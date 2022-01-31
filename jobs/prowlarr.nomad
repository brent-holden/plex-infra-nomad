job "prowlarr" {
  datacenters = ["lab"]
  type        = "service"
  priority    = 5

  group "prowlarr" {
    count = 1

    network {
      mode = "bridge"
      port "prowlarr" {}
    }

    service {
      name = "prowlarr"
      port = 9696

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "sabnzbd"
              local_bind_port  = 8080
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
            upstreams {
              destination_name = "readarr"
              local_bind_port  = 8787
            }
          }
        }
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.prowlarr.rule=Host(`plex-request.domain.name`) && PathPrefix(`/prowlarr`)",
        "traefik.http.routers.prowlarr.tls.certresolver=letsencrypt",
        "traefik.http.routers.prowlarr.entrypoints=web-secure",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name     = "prowlarr"
        type     = "http"
        port     = "prowlarr"
        path     = "/prowlarr/login"
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
      type  = "host"
      source = "prowlarr-config"
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

    task "prowlarr" {
      driver = "docker"

      volume_mount {
        volume = "config"
        destination = "/config"
      }

      env {
        PGID = "1100"
        PUID = "1100"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["prowlarr"]
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "prowlarr/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "prowlarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "prowlarr/config/release" "nightly" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
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
