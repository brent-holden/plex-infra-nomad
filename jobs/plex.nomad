job "plex" {
  datacenters = ["lab"]
  type        = "service"
  priority    = 20

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  update {
    max_parallel  = 0
    health_check  = "checks"
    auto_revert   = true
  }

  group "plex" {
    count = 1

    restart {
      interval  = "12h"
      attempts  = 720
      delay     = "60s"
      mode      = "delay"
    }

    network {
      port "plex" { static = 32400 }
    }

    service {
      name = "plex"
      tags = ["http","media"]
      port = "plex"

      check {
        type     = "http"
        port     = "plex"
        path     = "/web/index.html"
        interval = "30s"
        timeout  = "5s"

        check_restart {
          limit = 10000
          grace = "60s"
        }
      }
    }

    task "plex" {
      driver = "containerd-driver"

      env {
        PLEX_GID    = "1100"
        PLEX_UID    = "1100" 
        VERSION     = "docker"
        TZ          = "America/New_York"
        PLEX_CLAIM  = "claim-XXXXX"
      }

      config {
        image         = "docker.io/plexinc/pms-docker:${RELEASE}"
        host_network  = true
        mounts        = [
                          {
                            type    = "bind"
                            target  = "/config"
                            source  = "/opt/plex"
                            options = ["rbind", "rw"]
                          },
                          {
                            type    = "bind"
                            target  = "/media"
                            source  = "/mnt/rclone/media"
                            options = ["rbind", "ro"]
                          },
                          {
                            type    = "bind"
                            target  = "/transcode"
                            source  = "/mnt/transcode"
                            options = ["rbind", "rw"]
                          }
                    ]
      }

      template {
        data          = <<EOH
IMAGE_ID={{ keyOrDefault "plex/config/image_id" "1" }}
VERSION={{ keyOrDefault "plex/config/version" "1.0" }}
RELEASE={{ keyOrDefault "plex/config/release" "plexpass" }}
EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 8000
        memory = 32768
      }

      kill_timeout = "30s"
    }
  }
}
