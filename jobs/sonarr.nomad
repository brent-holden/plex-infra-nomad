job "sonarr" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

 update {
    max_parallel  = 0
    health_check  = "checks"
    auto_revert   = true
  }

  group "sonarr" {
    count = 1

    restart {
      interval  = "12h"
      attempts  = 720
      delay     = "60s"
      mode      = "delay"
    }

    network {
      mode  = "bridge"
      port "sonarr" { static = 8989 }
    }

    service {
      name = "sonarr"
      tags = ["http","music"]
      port = "sonarr"

      check {
        type      = "http"
        port      = "sonarr"
        path      = "/sonarr/login"
        interval  = "30s"
        timeout   = "2s"

        check_restart {
          limit = 10000
          grace = "60s"
        }
      }
    }

    task "sonarr" {
      driver = "containerd-driver"

      env {
        PGID  = "1100"
        PUID  = "1100"
        TZ    = "America/New_York"
      }

      config {
        image   = "docker.io/linuxserver/sonarr:${RELEASE}"
        mounts  = [
                    {
                      type    = "bind"
                      target  = "/config"
                      source  = "/opt/sonarr"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/downloads"
                      source  = "/mnt/downloads"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/tv"
                      source  = "/mnt/rclone/media/TV"
                      options = ["rbind", "rw"]
                    }
                  ]
      }

      template {
        data          = <<EOH
IMAGE_ID={{ keyOrDefault "sonarr/config/image_id" "1" }}
RELEASE={{ keyOrDefault "sonarr/config/release" "latest" }}"
EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 500
        memory = 2048
      }

      kill_timeout = "20s"
    }
  }
}
