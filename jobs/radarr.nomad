job "radarr" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "radarr" {
    count = 1

    network {
      mode  = "bridge"
      port "radarr" { to = -1 }
    }

    service {
      name = "radarr"
      port = 7878

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
        "traefik.http.routers.radarr.rule=PathPrefix(`/radarr`)",
      ]

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        name      = "radarr"
        type      = "http"
        port      = "radarr"
        path      = "/radarr/login"
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

    task "radarr" {
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
        image   = "${IMAGE}:${RELEASE}"
        ports   = [ "radarr" ]

        mount {
          type      = "bind"
          target    = "/config"
          source    = "/opt/radarr"
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
          target    = "/media/movies"
          source    = "/mnt/rclone/media/Movies"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

      }

      template {
        data          = <<-EOH
          IMAGE={{ key "radarr/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "radarr/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "radarr/config/release" "latest" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
          EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 300
        memory = 1024
      }

      kill_timeout = "20s"
    }
  }
}
