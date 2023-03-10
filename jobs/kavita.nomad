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
        "traefik.http.routers.kavita.entrypoints=[[ .app.kavita.traefik.entrypoints  ]]",
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
      type   = "host"
      source = "kavita-config"
    }

    volume "books" {
      type      = "host"
      source    = "media-books"
      read_only = true
    }

    update {
      max_parallel      = 1
      canary            = 1
      health_check      = "checks"
      auto_revert       = true
      auto_promote      = true
      min_healthy_time  = "10s"
      healthy_deadline  = "5m"
      progress_deadline = "10m"
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
          IMAGE_DIGEST={{ keyOrDefault "kavita/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "kavita/config/release" "latest" }}
          EOH
        destination = "env_info"
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
