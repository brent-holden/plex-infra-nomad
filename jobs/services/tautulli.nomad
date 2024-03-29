job "tautulli" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"

  group "tautulli" {
    count = 1

    network {
      mode = "bridge"
      port "tautulli" {}
      port "metrics_envoy" { to = 20200 }
    }

    service {
      name = "tautulli"
      port = 8181

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
        "traefik.http.routers.tautulli.rule=Host(`[[ .app.tautulli.traefik.hostname ]].[[ .app.traefik.domain.tld ]]`) && PathPrefix(`[[ .app.tautulli.traefik.path ]]`)",
        "traefik.http.routers.tautulli.entrypoints=[[ .app.tautulli.traefik.entrypoints ]]",
        "traefik.http.routers.tautulli.middlewares=[[ .app.authelia.traefik.middlewares ]]",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name     = "tautulli"
        type     = "http"
        port     = "tautulli"
        path     = "/status"
        interval = "60s"
        timeout  = "2s"
        expose   = true
      }
    }

    volume "config" {
      type   = "host"
      source = "tautulli-config"
    }

    update {
      max_parallel = 0
      health_check = "checks"
      auto_revert  = true
    }

    task "tautulli" {
      driver = "docker"

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      env {
        PUID = "[[ .common.env.puid ]]"
        PGID = "[[ .common.env.pgid ]]"
        TZ   = "America/New_York"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["tautulli"]

      }

      template {
        data        = <<-EOH
          IMAGE={{ key "tautulli/config/image" }}
          RELEASE={{ key "tautulli/config/release" }}
          IMAGE_DIGEST={{ keyOrDefault "tautulli/config/image_digest" "1" }}
          EOH
        destination = "local/env_info"
        env         = true
      }

      resources {
        cpu    = 500
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
