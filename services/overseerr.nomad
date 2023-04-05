job "overseerr" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"

  constraint {
    attribute = "${meta.download_node}"
    value     = "true"
  }

  group "overseerr" {
    count = 1

    network {
      mode = "bridge"
      port "overseerr" {}
      port "metrics_envoy" { to = 20200 }
    }

    service {
      name = "overseerr"
      port = 5055

      meta {
        metrics_port_envoy = "${NOMAD_HOST_PORT_metrics_envoy}"
      }

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:20200"
            }
            upstreams {
              destination_name = "radarr"
              local_bind_port  = 7878
            }
            upstreams {
              destination_name = "sonarr"
              local_bind_port  = 8989
            }
            upstreams {
              destination_name = "tautulli"
              local_bind_port  = 8181
            }
          }
        }
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.overseerr.rule=Host(`[[ .app.overseerr.traefik.hostname ]].[[ .app.traefik.domain.tld ]]`) && PathPrefix(`[[ .app.overseerr.traefik.path ]]`)",
        "traefik.http.routers.overseerr.entrypoints=[[ .app.overseerr.traefik.entrypoints  ]]",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name     = "overseerr"
        type     = "http"
        port     = "overseerr"
        path     = "/api/v1/status"
        interval = "60s"
        timeout  = "5s"
        expose   = true
        header {
          Accept = ["application/json"]
        }

        check_restart {
          limit = 10 
          grace = "60s"
        }
      }

    }

    volume "config" {
      type   = "host"
      source = "overseerr-config"
    }

    update {
      max_parallel = 0
      health_check = "checks"
      auto_revert  = true
    }

    task "overseerr" {
      driver = "docker"

      env {
        PGID = "[[ .common.env.puid ]]"
        PUID = "[[ .common.env.pgid ]]"
        TZ   = "America/New_York"
      }

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["overseerr"]
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "overseerr/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "overseerr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "overseerr/config/release" "latest" }}
          EOH
        destination = "env_info"
        env         = true
      }

      resources {
        cpu    = 300
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
