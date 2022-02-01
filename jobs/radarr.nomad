job "radarr" {
  datacenters = ["lab"]
  type        = "service"

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
        metrics_port_envoy = NOMAD_HOST_PORT_metrics_envoy
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
        "traefik.http.routers.radarr.rule=Host(`plex-request.domain.name`) && PathPrefix(`/radarr`)",
        "traefik.http.routers.radarr.tls.certresolver=letsencrypt",
        "traefik.http.routers.radarr.entrypoints=web-secure",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name     = "radarr"
        type     = "http"
        port     = "radarr"
        path     = "/radarr/login"
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
      max_parallel      = 1
      canary            = 1
      health_check      = "checks"
      auto_revert       = true
      auto_promote      = true
      min_healthy_time  = "10s"
      healthy_deadline  = "5m"
      progress_deadline = "10m"
    }

    task "radarr" {
      driver = "docker"

      env {
        PGID = "1100"
        PUID = "1100"
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
          ACME_HOST={{ key "traefik/config/acme_host" }}
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
