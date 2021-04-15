job "hydra2" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "hydra2" {
    count = 1

    network {
      mode = "bridge"
      port "hydra2" { to = 5076 }
    }

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    task "hydra2" {
      driver = "containerd-driver"

      service {
        name = "hydra2"
        port = "hydra2"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.hydra2.rule=Host(`${ACME_HOST}`) && PathPrefix(`/hydra2`)",
        ]

        check {
          type      = "http"
          port      = "hydra2"
          path      = "/hydra2/login.html"
          interval  = "30s"
          timeout   = "2s"

          check_restart {
            limit = 2
            grace = "10s"
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
      }

      config {
        image   = "docker.io/linuxserver/nzbhydra2:${RELEASE}"
        mounts  = [
                    {
                      type    = "bind"
                      target  = "/config"
                      source  = "/opt/hydra2"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/downloads"
                      source  = "/mnt/downloads"
                      options = ["rbind", "rw"]
                    }
                  ]
      }

      template {
        data          = <<EOH
IMAGE_DIGEST={{ keyOrDefault "hydra2/config/image_digest" "1" }}
RELEASE={{ keyOrDefault "hydra2/config/release" "latest" }}
ACME_HOST={{ key "traefik/config/acme_host" }}
EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 1000
        memory = 2048
      }

      kill_timeout = "20s"
    }
  }
}
