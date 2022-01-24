job "prowlarr" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "prowlarr" {
    count = 1

    network {
      mode = "bridge"
      port "prowlarr" { to = 9696 }
    }

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    task "prowlarr" {
      driver = "docker"

      service {
        name = "prowlarr"
        port = "prowlarr"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.prowlarr.rule=Host(`${ACME_HOST}`) && PathPrefix(`/prowlarr`)",
        ]

        check {
          type      = "http"
          port      = "prowlarr"
          path      = "/prowlarr/login"
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
        image   = "lscr.io/linuxserver/prowlarr:${RELEASE}"
        mount {
          type    = "bind"
          target  = "/config"
          source  = "/opt/prowlarr"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type    = "bind"
          target  = "/downloads"
          source  = "/mnt/downloads"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }

      }

      template {
        data          = <<-EOH
          IMAGE_DIGEST={{ keyOrDefault "prowlarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "prowlarr/config/release" "nightly" }}
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
