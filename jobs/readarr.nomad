job "readarr" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "readarr" {
    count = 1

    network {
      mode = "bridge"
      port "readarr" { to = 8787 }
    }

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    task "readarr" {
      driver = "docker"

      service {
        name = "readarr"
        port = "readarr"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.readarr.rule=Host(`${ACME_HOST}`) && PathPrefix(`/readarr`)",
        ]

        check {
          type      = "http"
          port      = "readarr"
          path      = "/readarr/login"
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
        image   = "ghcr.io/linuxserver/readarr:${RELEASE}"
        mount {
          type    = "bind"
          target  = "/config"
          source  = "/opt/readarr"
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

        mount {
          type    = "bind"
          target  = "/books"
          source  = "/mnt/rclone/media/Books"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }
      }

      template {
        data          = <<-EOH
          IMAGE_DIGEST={{ keyOrDefault "readarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "readarr/config/release" "nightly" }}
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
