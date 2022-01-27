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
      port "kavita" { to = -1 }
    }
  
    service {
      name = "kavita"
      port = 5000

      connect {
        sidecar_service {}
      } 

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.kavita.rule=Host(`KAVITA_DOMAIN_NAME`) && PathPrefix(`/`)",
        "traefik.http.routers.kavita.tls=true",
        "traefik.http.routers.kavita.tls.certresolver=letsencrypt",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name      = "kavita"
        type      = "http"
        port      = "kavita"
        path      = "/"
        interval  = "30s"
        timeout   = "2s"
        expose    = true

        check_restart {
          limit = 2
          grace = "30s"
        }
      }
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

    task "kavita" {
      driver = "docker"

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
        image = "${IMAGE}:${RELEASE}"
        ports = [ "kavita" ]

        mount {
          type      = "bind"
          target    = "/books"
          source    = "/mnt/rclone/media/Books"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type      = "bind"
          target    = "/kavita/config"
          source    = "/opt/kavita"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }
      }

      template {
        data          = <<-EOH
          IMAGE={{ key "kavita/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "kavita/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "kavita/config/release" "latest" }}
          KAVITA_HOST={{ key "kavita/config/kavita_host" }}
          EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 200
        memory = 512
      }

      kill_timeout = "20s"
    }
  }
}
