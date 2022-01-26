job "sabnzbd" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "sabnzbd" {
    count = 1

    network {
      mode = "bridge"
      port "sabnzbd" { static = 8080 }
    }

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    task "sabnzbd" {
      driver = "docker"

      service {
        name = "sabnzbd"
        port = "sabnzbd"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.sabnzbd.rule=Host(`${ACME_HOST}`) && PathPrefix(`/sabnzbd`)",
        ]

        check {
          type      = "http"
          port      = "sabnzbd"
          path      = "/sabnzbd/login/"
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
        image   = "${IMAGE}:${RELEASE}"

        mount {
          type    = "bind"
          target  = "/config"
          source  = "/opt/sabnzbd"
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
          IMAGE={{ key "sabnzbd/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "sabnzbd/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "sabnzbd/config/release" "latest" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
          EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 4000
        memory = 16384
      }

      kill_timeout = "20s"
    }
  }
}
