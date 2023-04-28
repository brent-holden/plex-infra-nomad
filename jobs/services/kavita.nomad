job "kavita" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"

  constraint {
    attribute = "${meta.download_node}"
    value     = "true"
  }

  group "kavita" {
    count = 1

    network {
      mode = "bridge"
      port "kavita" {}
      port "metrics_envoy" { to = 20200 }
    }

    service {
      name = "kavita"
      port = 5000

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
        "traefik.http.routers.kavita.rule=Host(`[[ .app.kavita.traefik.hostname ]].[[ .app.traefik.domain.tld ]]`) && PathPrefix(`[[ .app.kavita.traefik.path ]]`)",
        "traefik.http.routers.kavita.entrypoints=[[ .app.kavita.traefik.entrypoints ]]",
        "traefik.http.routers.kavita.middlewares=[[ .app.authelia.traefik.middlewares ]]",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name     = "kavita"
        type     = "http"
        port     = "kavita"
        path     = "/api/health"
        interval = "30s"
        timeout  = "2s"
        expose   = true

        check_restart {
          limit = 2
          grace = "30s"
        }
      }
    }

    volume "config" {
      type      = "host"
      source    = "kavita-config"
      read_only = false
    }

    volume "books" {
      type      = "host"
      source    = "media-books"
      read_only = true
    }

    update {
      max_parallel = 0
      health_check = "checks"
      auto_revert  = true
    }

    task "kavita" {
      driver = "docker"

      env {
        PGID = "[[ .common.env.puid ]]"
        PUID = "[[ .common.env.pgid ]]"
      }

      volume_mount {
        volume      = "config"
        destination = "/kavita/config"
      }

      volume_mount {
        volume      = "books"
        destination = "/books"
        read_only   = true
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["kavita"]
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "kavita/config/image" }}
          RELEASE={{ key "kavita/config/release" }}
          IMAGE_DIGEST={{ keyOrDefault "kavita/config/image_digest" "1" }}
          EOH
        destination = "local/env_info"
        env         = true
      }

      resources {
        cpu    = 200
        memory = 512
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
