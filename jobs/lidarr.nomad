job "lidarr" {
  datacenters = ["lab"]
  type        = "service"

  group "lidarr" {
    count = 1

    network {
      mode = "bridge"
      port "lidarr" {}
    }

    service {
      name = "lidarr"
      port = 8686

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
        "traefik.http.routers.lidarr.rule=Host(`plex-request.domain.name`) && PathPrefix(`/lidarr`)",
        "traefik.http.routers.lidarr.tls.certresolver=letsencrypt",
        "traefik.http.routers.lidarr.entrypoints=web-secure",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name     = "lidarr"
        type     = "http"
        port     = "lidarr"
        path     = "/lidarr/login"
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
      source = "lidarr-config"
    }

    volume "downloads" {
      type  = "host"
      source = "downloads"
    }

    volume "music" {
      type  = "host"
      source = "media-music"
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

    task "lidarr" {
      driver = "docker"

      env {
        PGID = "1100"
        PUID = "1100"
      }

      volume_mount {
        volume = "config"
        destination = "/config"
      }

      volume_mount {
        volume = "downloads"
        destination = "/downloads"
      }

      volume_mount {
        volume = "music"
        destination = "/music"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["lidarr"]
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "lidarr/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "lidarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "lidarr/config/release" "latest" }}
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
