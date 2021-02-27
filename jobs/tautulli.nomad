job "tautulli" {
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

  group "tautulli" {
    count = 1

    restart {
      interval  = "12h"
      attempts  = 720
      delay     = "60s"
      mode      = "delay"
    }

    network {
      mode  = "bridge"
      port "tautulli" { static = 8181 }
    }

    service {
      name = "tautulli"
      tags = ["http","music"]
      port = "tautulli"

      check {
        type     = "http"
        port     = "tautulli"
        path      = "/tautulli/auth/login"
        interval = "63s"
        timeout  = "2s"

        check_restart {
          limit = 10000
          grace = "60s"
        }
      }
    }

    task "tautulli" {
      driver = "containerd-driver"

      env {
        PGID  = "1100"
        PUID  = "1100"
        TZ    = "America/New_York"
      }

      config {
        image         = "docker.io/linuxserver/tautulli:${RELEASE}"

        mounts  = [
                    {
                      type    = "bind"
                      target  = "/config"
                      source  = "/opt/tautulli"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/plex_logs"
                      source  = "/opt/plex/Library/Application Support/Plex Media Server/Logs"
                      options = ["rbind", "ro"]
                    }
                  ]
      }

      template {
        data          = <<EOH
IMAGE_ID={{ keyOrDefault "tautulli/config/image_id" "1" }}
RELEASE={{ keyOrDefault "tautulli/config/release" "latest" }}
EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 300
        memory = 512
      }

      kill_timeout = "20s"
    }
  }
}
