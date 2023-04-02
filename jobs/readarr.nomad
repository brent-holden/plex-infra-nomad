job "readarr" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"

  constraint {
    attribute = "${meta.download_node}"
    value     = "true"
  }

  group "readarr" {
    count = 1

    network {
      mode = "bridge"
      port "readarr" {}
      port "metrics_envoy" { to = 20200 }
    }

    service {
      name = "readarr"
      port = 8787

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
        "traefik.http.routers.readarr.rule=Host(`[[ .app.readarr.traefik.hostname ]].[[ .app.traefik.domain.tld ]]`) && PathPrefix(`[[ .app.readarr.traefik.path ]]`)",
        "traefik.http.routers.readarr.entrypoints=[[ .app.readarr.traefik.entrypoints ]]",
        "traefik.http.routers.readarr.middlewares=[[ .app.authelia.traefik.middlewares ]]",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name     = "readarr"
        type     = "http"
        port     = "readarr"
        path     = "/readarr/ping"
        interval = "30s"
        timeout  = "2s"
        expose   = true

        check_restart {
          limit = 2
          grace = "30s"
        }
      }
    }

    #    volume "config" {
    #      type            = "csi"
    #      source          = "readarr-config"
    #      attachment_mode = "file-system"
    #      access_mode     = "multi-node-multi-writer"
    #    }

    volume "config" {
      type   = "host"
      source = "readarr-config-host"
    }

    volume "downloads" {
      type   = "host"
      source = "downloads"
    }

    volume "books" {
      type   = "host"
      source = "media-books"
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

    task "readarr" {
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
        volume      = "books"
        destination = "/books"
      }

      env {
        PUID = "[[ .common.env.puid ]]"
        PGID = "[[ .common.env.pgid ]]"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["readarr"]
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "readarr/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "readarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "readarr/config/release" "nightly" }}
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
