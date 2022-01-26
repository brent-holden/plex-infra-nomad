job "radarr" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "radarr" {
    count = 1

    network {
      mode  = "bridge"
      port "radarr" { to = 7878 }
    }

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    task "radarr" {
      driver = "docker"
      service {
        name = "radarr"
        port = "radarr"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.radarr.rule=Host(`${ACME_HOST}`) && PathPrefix(`/radarr`)",
        ]

        check {
          type      = "http"
          port      = "radarr"
          path      = "/radarr/login"
          interval  = "30s"
          timeout   = "2s"

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
        image   = "${IMAGE}:${RELEASE}"

        mount {
          type      = "bind"
          target    = "/config"
          source    = "/opt/radarr"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type      = "bind"
          target    = "/downloads"
          source    = "/mnt/downloads"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type      = "bind"
          target    = "/media/movies"
          source    = "/mnt/rclone/media/Movies"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

      }

      template {
        data          = <<-EOH
          IMAGE={{ key "radarr/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "radarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "radarr/config/release" "latest" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
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
