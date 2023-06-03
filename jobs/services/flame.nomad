job "flame" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"

  group "flame" {
    count = 1

    network {
      mode = "bridge"
      port "flame" {}
      port "metrics_envoy" { to = 20200 }
    }

    service {
      name = "flame"
      port = 5005

      meta {
        metrics_port_envoy = "${NOMAD_HOST_PORT_metrics_envoy}"
      }

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:20200"
            }
          }
        }
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.flame.rule=Host(`[[ .app.flame.traefik.hostname ]].[[ .app.traefik.domain.tld ]]`) && PathPrefix(`[[ .app.flame.traefik.path ]]`)",
        "traefik.http.routers.flame.entrypoints=[[ .app.flame.traefik.entrypoints  ]]",
        "traefik.http.routers.flame.middlewares=[[ .app.authelia.traefik.middlewares ]]",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

#      check {
#        name     = "flame"
#        type     = "http"
#        port     = "flame"
#        path     = "/"
#        interval = "30s"
#        timeout  = "2s"
#        expose   = true
#      }
    }

    volume "config" {
      type   = "host"
      source = "flame-config"
    }

    update {
      max_parallel = 0
      health_check = "checks"
      auto_revert  = true
    }

    task "flame" {
      driver = "docker"

      env {
        PUID = "[[ .common.env.puid ]]"
        PGID = "[[ .common.env.pgid ]]"
        TZ   = "America/New_York"
      }

      volume_mount {
        volume      = "config"
        destination = "/app/data"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["flame"]
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "flame/config/image" }}
          RELEASE={{ key "flame/config/release" }}
          IMAGE_DIGEST={{ keyOrDefault "flame/config/image_digest" "1" }}
          EOH
        destination = "local/env_info"
        env         = true
      }

      template {
        data        = <<-EOH
          PASSWORD={{ key "flame/config/password" }}
          EOH
        destination = "secrets/password"
        env         = true
      }

      resources {
        cpu    = 300
        memory = 1024
      }

      restart {
        interval = "12h"
        attempts = 720
        delay    = "60s"
        mode     = "delay"
      }

      kill_timeout = "20s"
    }
  }
}
