job "sonarr" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"

  constraint {
    attribute = "${meta.download_node}"
    value     = "true"
  }

  group "sonarr" {
    count = 1

    network {
      mode = "bridge"
      port "sonarr" {}
      port "metrics_envoy" { to = 20200 }
    }

    service {
      name = "sonarr"
      port = 8989

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
        "traefik.http.routers.sonarr.rule=Host(`[[ .app.sonarr.traefik.hostname ]].[[ .app.traefik.domain.tld ]]`) && PathPrefix(`[[ .app.sonarr.traefik.path ]]`)",
        "traefik.http.routers.sonarr.entrypoints=[[ .app.sonarr.traefik.entrypoints ]]",
        "traefik.http.routers.sonarr.middlewares=[[ .app.authelia.traefik.middlewares ]]",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name     = "sonarr"
        type     = "http"
        port     = "sonarr"
        path     = "/ping"
        interval = "30s"
        timeout  = "2s"
        expose   = true
      }
    }

    volume "config" {
      type   = "host"
      source = "sonarr-config"
    }

    volume "downloads" {
      type   = "host"
      source = "downloads"
    }

    volume "tv" {
      type   = "host"
      source = "media-tv"
    }

    update {
      max_parallel = 0
      health_check = "checks"
      auto_revert  = true
    }

    task "sonarr" {
      driver = "docker"

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      volume_mount {
        volume      = "downloads"
        destination = "/downloads"
      }

      volume_mount {
        volume      = "tv"
        destination = "/tv"
      }

      env {
        PUID = "[[ .common.env.puid ]]"
        PGID = "[[ .common.env.pgid ]]"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["sonarr"]
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "sonarr/config/image" }}
          RELEASE={{ key "sonarr/config/release" }}
          IMAGE_DIGEST={{ keyOrDefault "sonarr/config/image_digest" "1" }}
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
