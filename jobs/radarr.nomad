job "radarr" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"

  constraint {
    attribute = "${meta.download_node}"
    value     = "true"
  }

  group "radarr" {
    count = 1

    network {
      mode = "bridge"
      port "radarr" {}
      port "metrics_envoy" { to = 20200 }
    }

    service {
      name = "radarr"
      port = 7878

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
              destination_name = "prowlarr"
              local_bind_port  = 9696
            }
          }
        }
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.radarr.rule=Host(`[[ .app.radarr.traefik.hostname ]].[[ .app.traefik.domain.tld ]]`) && PathPrefix(`[[ .app.radarr.traefik.path ]]`)",
        "traefik.http.routers.radarr.entrypoints=[[ .app.radarr.traefik.entrypoints  ]]",
        "traefik.http.routers.radarr.middlewares=[[ .app.authelia.traefik.middlewares ]]",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name     = "radarr"
        type     = "http"
        port     = "radarr"
        path     = "/radarr/ping"
        interval = "120s"
        timeout  = "10s"
        expose   = true

        check_restart {
          limit = 10
          grace = "30s"
        }
      }
    }

    volume "config" {
      type   = "host"
      source = "radarr-config"
    }

    volume "downloads" {
      type   = "host"
      source = "downloads"
    }

    volume "movies" {
      type   = "host"
      source = "media-movies"
    }

    update {
      max_parallel = 0
      health_check = "checks"
      auto_revert  = true
    }

    task "radarr" {
      driver = "docker"

      env {
        PUID = "[[ .common.env.puid ]]"
        PGID = "[[ .common.env.pgid ]]"
        TZ   = "America/New_York"
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
        volume      = "movies"
        destination = "/media/movies"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["radarr"]
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "radarr/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "radarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "radarr/config/release" "latest" }}
          EOH
        destination = "env_info"
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
