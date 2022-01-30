job "sonarr" {
  datacenters = ["lab"]
  type        = "service"

  constraint {
    attribute = meta.media_node
    value     = "true"
  }

  group "sonarr" {
    count = 1

    network {
      mode = "bridge"
      port "sonarr" {}
    }

    service {
      name = "sonarr"
      port = 8989

      connect {
        sidecar_service {
          proxy {
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
        "traefik.http.routers.sonarr.rule=Host(`plex-request.eventide.network`) && PathPrefix(`/sonarr`)",
        "traefik.http.routers.sonarr.tls.certresolver=letsencrypt",
        "traefik.http.routers.sonarr.entrypoints=web-secure",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name     = "sonarr"
        type     = "http"
        port     = "sonarr"
        path     = "/sonarr/login"
        interval = "30s"
        timeout  = "2s"
        expose   = true

        check_restart {
          limit = 2
          grace = "30s"
        }
      }
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

      restart {
        interval = "12h"
        attempts = 720
        delay    = "60s"
        mode     = "delay"
      }

      env {
        PGID = "1100"
        PUID = "1100"
      }

      config {
        image = "${IMAGE}:${RELEASE}"

        mount {
          type     = "bind"
          target   = "/config"
          source   = "/opt/sonarr"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type     = "bind"
          target   = "/downloads"
          source   = "/mnt/downloads"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type     = "bind"
          target   = "/tv"
          source   = "/mnt/rclone/media/TV"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }

      }

      template {
        data        = <<-EOH
          IMAGE={{ key "sonarr/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "sonarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "sonarr/config/release" "latest" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
          EOH
        destination = "env_info"
        env         = true
      }

      resources {
        cpu    = 350
        memory = 1024
      }

      kill_timeout = "20s"
    }
  }
}
