job "kavita" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "kavita" {
    count = 1

    network {
      mode = "bridge"
      port "kavita" { to = 5000 }
    }

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    task "kavita" {
      driver = "docker"

      service {
        name = "kavita"
        port = "kavita"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.kavita.rule=Host(`${KAVITA_HOST}`)",
          "traefik.http.routers.kavita.tls=true",
          "traefik.http.routers.kavita.tls.certresolver=letsencrypt",
        ]

        check {
          type      = "http"
          port      = "kavita"
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
      }

      config {
        image = "docker.io/kizaing/kavita:${RELEASE}"

        mount {
          type    = "bind"
          target  = "/books"
          source  = "/mnt/rclone/media/Books"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type    = "bind"
          target  = "/kavita/config"
          source  = "/opt/kavita"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }
      }

      template {
        data          = <<-EOH
          IMAGE_DIGEST={{ keyOrDefault "kavita/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "kavita/config/release" "latest" }}
          KAVITA_HOST={{ key "kavita/config/kavita_host" }}
          EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 100
        memory = 512
      }

      kill_timeout = "20s"
    }
  }
}
