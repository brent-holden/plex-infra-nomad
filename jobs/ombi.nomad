job "ombi" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "ombi" {
    count = 1

    network {
      mode = "bridge"
      port "ombi" { to = 3579 }
    }

    update {
      max_parallel  = 1
      canary        = 1
      health_check  = "checks"
      auto_revert   = true
      auto_promote  = true
      min_healthy_time  = "10s"
      healthy_deadline  = "5m"
      progress_deadline = "10m"
    }

    task "ombi" {
      driver = "docker"

      service {
        name = "ombi"
        port = "ombi"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.ombi.rule=Host(`${ACME_HOST}`) && PathPrefix(`/ombi`)",
          "traefik.frontend.redirect.regex=^https:\\\\/\\\\/([^\\\\/]+)\\\\/?$$",
          "traefik.frontend.redirect.replacement=https://$$1/ombi/",
        ]

        canary_tags = [
          "traefik.enable=false",
        ]

        check {
          type      = "http"
          port      = "ombi"
          path      = "/"
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
       TZ   = "America/New_York"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = [ "ombi" ]

        mount {
          type      = "bind"
          target    = "/config"
          source    = "/opt/ombi"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

      }

      template {
        data          = <<-EOH
          IMAGE={{ key "ombi/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "ombi/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "ombi/config/release" "latest" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
          EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 200
        memory = 1024
      }

      kill_timeout = "20s"
    }
  }
}
