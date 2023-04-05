job "caddy" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"

  constraint {
    attribute = "${meta.download_node}"
    value     = "true"
  }

  group "caddy" {
    count = 1

    network {
      mode = "bridge"
      port "caddy" {}
      port "caddy_admin" { static = 2019 }
      port "metrics_envoy" { to = 20200 }
    }

    service {
      name = "caddy"
      port = 80

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
        "traefik.http.routers.caddy.rule=Host(`[[ .app.caddy.traefik.hostname ]].[[ .app.traefik.domain.tld ]]`) && PathPrefix(`[[ .app.caddy.traefik.path ]]`)",
        "traefik.http.routers.caddy.entrypoints=[[ .app.caddy.traefik.entrypoints ]]",
        "traefik.http.routers.caddy.middlewares=[[ .app.authelia.traefik.middlewares ]]",
      ]

      check {
        name     = "caddy"
        type     = "http"
        port     = "caddy"
        path     = "/health"
        interval = "30s"
        timeout  = "2s"
        expose   = true

        check_restart {
          limit = 2
          grace = "30s"
        }
      }
    }

    volume "downloads" {
      type      = "host"
      source    = "downloads"
      read_only = true
    }

    update {
      max_parallel = 0
      health_check = "checks"
      auto_revert  = true
    }

    task "caddy" {
      driver = "docker"

      volume_mount {
        volume      = "downloads"
        destination = "/downloads"
      }

      config {
        image   = "${IMAGE}:${RELEASE}"
        command = "caddy"
        ports   = ["caddy"]

        args = [
          "run",
          "--config",
          "/local/Caddyfile"
        ]

      }

      restart {
        interval = "12h"
        attempts = 720
        delay    = "60s"
        mode     = "delay"
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "caddy/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "caddy/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "caddy/config/release" "latest" }}
          EOH
        destination = "env_info"
        env         = true
      }

      template {
        destination = "/local/Caddyfile"
        data        = <<-EOH
          {
            admin       :2019
            auto_https  off
          }

          :80 {
            respond /health 200

            redir /downloads /downloads/
            handle_path /downloads/* {
              file_server browse
              root * /downloads
            }

            log {
              output stdout
            }

          }
          EOH
        change_mode = "restart"
      }

      resources {
        cpu    = 200
        memory = 512
      }

      kill_timeout = "20s"
    }
  }
}
