job "tautulli" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "tautulli" {
    count = 1

    network {
      mode  = "bridge"
      port "tautulli" { to = -1 }
    }

    service {
      name = "tautulli"
      port = 8181

      connect {
        sidecar_service {}
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.tautulli.rule=PathPrefix(`/${NOMAD_GROUP_NAME}`)",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name      = "tautulli"
        type      = "http"
        port      = "tautulli"
        path      = "/${NOMAD_GROUP_NAME}/auth/login"
        interval  = "60s"
        timeout   = "2s"
        expose    = true

        check_restart {
          limit = 2
          grace = "10s"
        }
      }
    }

    update {
      max_parallel  = 1
      canary        = 1
      health_check  = "checks"
      auto_revert   = true
      auto_promote  = true
      min_healthy_time  = "10s"
      healthy_deadline  = "5m"
      progress_deadline = "10m"
    }

    task "tautulli" {
      driver = "docker"

      restart {
        interval  = "12h"
        attempts  = 720
        delay     = "60s"
        mode      = "delay"
      }

      env {
        PGID  = "1100"
        PUID  = "1100"
        TZ    = "America/New_York"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
#        ports = [ "tautulli" ]

        mount {
          type      = "bind"
          target    = "/config"
          source    = "/opt/tautulli"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type      = "bind"
          target    = "/plex_logs"
          source    = "/opt/plex/Library/Application Support/Plex Media Server/Logs"
          readonly  = true
          bind_options {
            propagation = "rshared"
          }
        }

      }

      template {
        data          = <<-EOH
          IMAGE={{ key "tautulli/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "tautulli/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "tautulli/config/release" "latest" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
          EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 150
        memory = 512
      }

      kill_timeout = "20s"
    }
  }
}
