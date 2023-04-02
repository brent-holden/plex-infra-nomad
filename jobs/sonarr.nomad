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
        path     = "/sonarr/ping"
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
    #      source          = "sonarr-config"
    #      attachment_mode = "file-system"
    #      access_mode     = "multi-node-multi-writer"
    #    }

    volume "config" {
      type   = "host"
      source = "sonarr-config-host"
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
      max_parallel      = 1
      canary            = 1
      health_check      = "checks"
      auto_revert       = true
      auto_promote      = true
      min_healthy_time  = "10s"
      healthy_deadline  = "5m"
      progress_deadline = "10m"
    }

    task "sonarr" {
      driver = "docker"

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      #      volume_mount {
      #        volume      = "juice-config"
      #        destination = "/juice-config"
      #      }

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
          IMAGE_DIGEST={{ keyOrDefault "sonarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "sonarr/config/release" "latest" }}
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
