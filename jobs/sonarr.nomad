job "sonarr" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "sonarr" {
    count = 1

    network {
      mode  = "bridge"
      port "sonarr" { to = 8989 }
    }

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    task "sonarr" {
      driver = "docker"

      service {
        name = "sonarr"
        port = "sonarr"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.sonarr.rule=Host(`${ACME_HOST}`) && PathPrefix(`/sonarr`)",
        ]

        check {
          type      = "http"
          port      = "sonarr"
          path      = "/sonarr/login/"
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
        PGID = "1100"
        PUID = "1100" 
      }

      config {
        image       = "ghcr.io/linuxserver/sonarr:${RELEASE}"

        mount {
          type      = "bind"
          target    = "/config"
          source    = "/opt/sonarr"
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
          target    = "/tv"
          source    = "/mnt/rclone/media/TV"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

      }

      template {
        data          = <<-EOH
          IMAGE_DIGEST={{ keyOrDefault "sonarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "sonarr/config/release" "latest" }}
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
