job "plex" {
  datacenters = ["lab"]
  type        = "service"
  priority    = 20

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "plex" {
    count = 1

    network {
      port "plex" { static = 32400 }
    }

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    task "plex" {
      driver = "docker"

      service {
        name = "plex"
        port = "plex"
        tags = ["media"]

        check {
          type     = "http"
          port     = "plex"
          path     = "/web/index.html"
          interval = "5m"
          timeout  = "5s"

          check_restart {
            limit = 2
            grace = "60s"
          }
        }
      }
    
      restart {
        interval  = "12h"
        attempts  = 720
        delay     = "60s"
        mode      = "delay"
      }

      env {
        PLEX_GID    = "1100"
        PLEX_UID    = "1100" 
        VERSION     = "docker"
        TZ          = "America/New_York"
        PLEX_CLAIM  = "${PLEX_CLAIM}"
      }

      config {
        image         = "docker.io/plexinc/pms-docker:${RELEASE}"

        network_mode  = "host"

        mount {
          type    = "bind"
          target  = "/config"
          source  = "/opt/plex"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type    = "bind"
          target  = "/media"
          source  = "/mnt/rclone/media"
          readonly = true
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type    = "bind"
          target  = "/transcode"
          source  = "/mnt/transcode"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }

      }

      template {
        data          = <<-EOH
          IMAGE_DIGEST={{ keyOrDefault "plex/config/image_digest" "1" }}
          VERSION={{ keyOrDefault "plex/config/version" "1.0" }}
          RELEASE={{ keyOrDefault "plex/config/release" "plexpass" }}
          PLEX_CLAIM={{ keyOrDefault "plex/config/claim_token" "claim-XXXXX" }}
          EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 8000
        memory = 32768
      }

      kill_timeout = "30s"
    }
  }
}
