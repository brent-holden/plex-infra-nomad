job "ombi" {
  datacenters = ["lab"]
  type        = "service"

  group "ombi" {
    count = 1

    network {
      mode = "bridge"
      port "ombi" {}
      port "metrics_envoy" { to = 20200 }
    }

    service {
      name = "ombi"
      port = 3579

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
          }
        }
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.ombi.rule=Host(`plex-request.domain.name`) && PathPrefix(`/ombi`)",
        "traefik.http.routers.ombi.tls.certresolver=letsencrypt",
        "traefik.http.routers.ombi.entrypoints=web-secure",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name     = "ombi"
        type     = "http"
        port     = "ombi"
        path     = "/"
        interval = "30s"
        timeout  = "2s"
        expose   = true

        check_restart {
          limit = 2
          grace = "10s"
        }
      }
    }

    volume "config" {
      type   = "host"
      source = "ombi-config"
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

    task "ombi" {
      driver = "docker"

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      env {
        PGID = "1100"
        PUID = "1100"
        TZ   = "America/New_York"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["ombi"]
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "ombi/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "ombi/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "ombi/config/release" "latest" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
          EOH
        destination = "env_info"
        env         = true
      }

      resources {
        cpu    = 200
        memory = 512
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
