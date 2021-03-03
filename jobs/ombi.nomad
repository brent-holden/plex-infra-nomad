job "ombi" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "ombi" {
    count = 1

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    network {
      mode = "bridge"
      port "ombi" { to = 3579 }
    }

    task "ombi" {
      driver = "containerd-driver"

      service {
        name = "ombi"
        port = "ombi"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.ombi.rule=PathPrefix(`/`)",
        ]

        check {
          type      = "http"
          port      = "ombi"
          path      = "/"
          interval  = "30s"
          timeout   = "2s"

          check_restart {
            limit = 10000
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
       PGID = "1100"
       PUID = "1100"
       TZ   = "America/New_York"
      }

      config {
        image         = "docker.io/linuxserver/ombi:${RELEASE}"
        mounts  = [
                    {
                      type    = "bind"
                      target  = "/config"
                      source  = "/opt/ombi"
                      options = ["rbind", "rw"]
                    }
                  ]
      }

      template {
        data          = <<EOH
IMAGE_ID={{ keyOrDefault "ombi/config/image_id" "1" }}
RELEASE={{ keyOrDefault "ombi/config/release" "latest" }}
EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 100
        memory = 2048
      }

      kill_timeout = "20s"
    }
  }
}
