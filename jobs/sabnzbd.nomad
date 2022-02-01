job "sabnzbd" {
  datacenters = ["lab"]
  type        = "service"
  priority    = 5

  group "sabnzbd" {
    count = 1

    network {
      mode = "bridge"
      port "sabnzbd" {}
      port "metrics_envoy" { to = 20200 }
    }

    service {
      name = "sabnzbd"
      port = 8080

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
        "traefik.http.routers.sabnzbd.rule=Host(`plex-request.domain.name`) && PathPrefix(`/sabnzbd`)",
        "traefik.http.routers.sabnzbd.tls.certresolver=letsencrypt",
        "traefik.http.routers.sabnzbd.entrypoints=web-secure",
      ]

      check {
        name     = "sabnzbd"
        type     = "http"
        port     = "sabnzbd"
        path     = "/sabnzbd/login/"
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
      source = "sabnzbd-config"
    }

    volume "downloads" {
      type   = "host"
      source = "downloads"
    }

    update {
      max_parallel = 0
      health_check = "checks"
      auto_revert  = true
    }

    task "sabnzbd" {
      driver = "docker"

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      volume_mount {
        volume      = "downloads"
        destination = "/downloads"
      }

      env {
        PGID = "1100"
        PUID = "1100"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["sabnzbd"]
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "sabnzbd/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "sabnzbd/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "sabnzbd/config/release" "latest" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
          EOH
        destination = "env_info"
        env         = true
      }

      resources {
        cpu    = 2000
        memory = 8192
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
