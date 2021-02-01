job "plex" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  update {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "5s"
    healthy_deadline = "2m"
    progress_deadline = "3m"
    auto_revert = true
    canary = 0
  }

  group "plex" {
    count = 1

    restart {
      interval = "2h"
      attempts = 10
      delay = "60s"
      mode = "delay"
    }

    network {
      port "plex" {
        static = 32400
      }
    }

    service {
      name = "plex"
      tags = ["http","media"]
      port = "plex"

      check {
        type     = "http"
        port     = "plex"
        path     = "/web"
        interval = "30s"
        timeout  = "5s"

        check_restart {
          limit = 2
          grace = "60s"
        }
      }
    }

    ephemeral_disk {
      sticky = true
      size = 10240
    }

    task "plex" {
      driver = "podman"

      env {
        PLEX_GID = "1100"
        PLEX_UID = "1100" 
        VERSION = "docker"
        TZ="America/New_York"
        PLEX_CLAIM="claim-XXXXX"
      }

      config {
        image = "docker://plexinc/pms-docker:plexpass"
        network_mode = "host"
        ports = ["plex"]
        volumes = ["/opt/plex:/config","/mnt/rclone/media:/media:ro","/mnt/transcode:/transcode"]
      }

      template {
        data = <<EOF
IMAGE_ID={{ key "pms-docker/config/version" }}
EOF

        destination = "image_id.env"
        env = true
      }

      resources {
        cpu    = 8000
        memory = 32768
      }

      kill_timeout = "30s"
    }
  }
}
