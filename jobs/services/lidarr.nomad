job "lidarr" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"

  constraint {
    attribute = "${meta.download_node}"
    value     = "true"
  }

  group "lidarr" {
    count = 1

    network {
      mode = "bridge"
      port "lidarr" {}
      port "metrics_envoy" { to = 20200 }
    }

    service {
      name = "lidarr"
      port = 8686

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
              destination_name = "authelia"
              local_bind_port  = 9091
            }
            upstreams {
              destination_name = "sabnzbd"
              local_bind_port  = 8080
            }
            upstreams {
              destination_name = "prowlarr"
              local_bind_port  = 9696
            }
          }
        }
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.lidarr.rule=Host(`[[ .app.lidarr.traefik.hostname ]].[[ .app.traefik.domain.tld ]]`) && PathPrefix(`[[ .app.lidarr.traefik.path ]]`)",
        "traefik.http.routers.lidarr.entrypoints=[[ .app.lidarr.traefik.entrypoints ]]",
        "traefik.http.routers.lidarr.middlewares=[[ .app.authelia.traefik.middlewares ]]",
      ]

      check {
        name     = "lidarr"
        type     = "http"
        port     = "lidarr"
        path     = "/lidarr/ping"
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
      source = "lidarr-config"
    }

    volume "downloads" {
      type   = "host"
      source = "downloads"
    }

    volume "music" {
      type   = "host"
      source = "media-music"
    }

    update {
      max_parallel = 0
      health_check = "checks"
      auto_revert  = true
    }

    task "lidarr" {
      driver = "docker"

      env {
        PUID = "[[ .common.env.puid ]]"
        PGID = "[[ .common.env.pgid ]]"
      }

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      volume_mount {
        volume      = "downloads"
        destination = "/downloads"
      }

      volume_mount {
        volume      = "music"
        destination = "/music"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["lidarr"]
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "lidarr/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "lidarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "lidarr/config/release" "latest" }}
          EOH
        destination = "local/env_info"
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
