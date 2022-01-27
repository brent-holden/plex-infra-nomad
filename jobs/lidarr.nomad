job "lidarr" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "lidarr" {
    count = 1

    network {
      mode  = "bridge"
      port "lidarr" { to = -1 }
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
          }
        }
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.lidarr.rule=PathPrefix(`/lidarr`)",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name      = "lidarr"
        type      = "http"
        port      = "lidarr"
        path      = "/lidarr/login"
        interval  = "30s"
        timeout   = "2s"
        expose    = true

        check_restart {
          limit = 2
          grace = "30s"
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

    task "lidarr" {
      driver = "docker"

      restart {
        interval  = "12h"
        attempts  = 720
        delay     = "60s"
        mode      = "delay"
      }

      env {
        PGID = "1100"
        PUID = "1100" 
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = [ "lidarr" ]

        mount {
          type      = "bind"
          target    = "/config"
          source    = "/opt/lidarr"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type      = "bind"
          target    = "/downloads"
          source    = "/mnt/downloads"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type      = "bind"
          target    = "/music"
          source    = "/mnt/rclone/media/Music"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

      }

      template {
        data          = <<-EOH
          IMAGE={{ key "lidarr/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "lidarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "lidarr/config/release" "latest" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
          EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 350
        memory = 1024
      }

      kill_timeout = "20s"
    }
  }
}
