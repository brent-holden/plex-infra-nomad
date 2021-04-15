job "tautulli" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "tautulli" {
    count = 1

    network {
      mode  = "bridge"
      port "tautulli" { to = 8181 }
    }

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    task "tautulli" {
      driver = "containerd-driver"

      service {
        name = "tautulli"
        port = "tautulli"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.tautulli.rule=Host(`${ACME_HOST}`) && PathPrefix(`/tautulli`)",
        ]

        check {
          type     = "http"
          port     = "tautulli"
          path      = "/tautulli/auth/login"
          interval = "63s"
          timeout  = "2s"

          check_restart {
            limit = 2
            grace = "10s"
          }
        }
      }

      restart {
        interval  = "12h"
        attempts  = 720
        delay     = "60s"
        mode      = "delay"
      }

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
IMAGE_DIGEST={{ keyOrDefault "tautulli/config/image_digest" "1" }}
RELEASE={{ keyOrDefault "tautulli/config/release" "latest" }}
ACME_HOST={{ key "traefik/config/acme_host" }}
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
