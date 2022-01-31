job "tautulli" {
  datacenters = ["lab"]
  type        = "service"

  group "tautulli" {
    count = 1

    network {
      mode = "bridge"
      port "tautulli" {}
    }

    service {
      name = "tautulli"
      port = 8181

      connect {
        sidecar_service {}
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.tautulli.rule=Host(`plex-request.domain.name`) && PathPrefix(`/tautulli`)",
        "traefik.http.routers.tautulli.tls.certresolver=letsencrypt",
        "traefik.http.routers.tautulli.entrypoints=web-secure",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name     = "tautulli"
        type     = "http"
        port     = "tautulli"
        path     = "/tautulli/auth/login"
        interval = "60s"
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
      source = "tautulli-config"
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

    task "tautulli" {
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
        ports = ["tautulli"]

      }

      template {
        data        = <<-EOH
          IMAGE={{ key "tautulli/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "tautulli/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "tautulli/config/release" "latest" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
          EOH
        destination = "env_info"
        env         = true
      }

      resources {
        cpu    = 150
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
