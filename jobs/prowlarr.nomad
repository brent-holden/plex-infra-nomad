job "prowlarr" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"
  priority    = 5

  constraint {
    attribute = "${meta.download_node}"
    value     = "true"
  }

  group "prowlarr" {
    count = 1

    network {
      mode = "bridge"
      port "prowlarr" {}
      port "metrics_envoy" { to = 20200 }
    }

    service {
      name = "prowlarr"
      port = 9696

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
              destination_name = "sabnzbd"
              local_bind_port  = 8080
            }
            upstreams {
              destination_name = "lidarr"
              local_bind_port  = 8686
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
              destination_name = "readarr"
              local_bind_port  = 8787
            }
          }
        }
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.prowlarr.rule=Host(`[[ .app.prowlarr.traefik.hostname ]].[[ .app.traefik.domain.tld ]]`) && PathPrefix(`[[ .app.prowlarr.traefik.path ]]`)",
        "traefik.http.routers.prowlarr.entrypoints=[[ .app.prowlarr.traefik.entrypoints  ]]",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name     = "prowlarr"
        type     = "http"
        port     = "prowlarr"
        path     = "/prowlarr/ping"
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
      source = "prowlarr-config"
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

    task "prowlarr" {
      driver = "docker"

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      env {
        PUID = "[[ .common.env.puid ]]"
        PGID = "[[ .common.env.pgid ]]"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["prowlarr"]
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "prowlarr/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "prowlarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "prowlarr/config/release" "nightly" }}
          EOH
        destination = "env_info"
        env         = true
      }

      resources {
        cpu    = 350
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
