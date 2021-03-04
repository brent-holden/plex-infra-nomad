job "caddy" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "caddy" {
    count = 1

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    network {
      mode  = "bridge"
      port "caddy" { to = 2020 }
    }

    task "caddy" {
      driver = "containerd-driver"

      service {
        name = "caddy"
        port = "caddy"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.caddy.rule=Host(`${ACME_HOST}`) && PathPrefix(`/downloads`)",
        ]

        check {
          type     = "tcp"
          port     = "caddy"
          interval = "30s"
          timeout  = "2s"

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

      config {
        image         = "docker.io/library/caddy:${RELEASE}"
        command       = "caddy"
        args          = [
                          "run",
                          "-config",
                          "local/Caddyfile"
                        ]

        mounts        = [
                          {
                            type    = "bind"
                            source  = "/opt/caddy/config"
                            target  = "/config"
                            options = ["rbind", "rw"]
                          },
                          {
                            type    = "bind"
                            source  = "/opt/caddy/data"
                            target  = "/data"
                            options = ["rbind", "rw"]
                          },
                          {
                            type    = "bind"
                            target  = "/downloads"
                            source  = "/mnt/downloads/complete"
                            options = ["rbind", "ro"]
                          }
                        ]
      }

      template {
        data          = <<EOH
IMAGE_DIGEST={{ keyOrDefault "caddy/config/image_digest" "1" }}
RELEASE={{ keyOrDefault "caddy/config/release" "latest" }}
ACME_HOST={{ key "traefik/config/acme_host" }}
EOH
        destination   = "env_info"
        env           = true
      }

      template {
        data        = <<EOH
{
  admin       off
  auto_https  off
}

http://:2020 {
  handle_path   /downloads* {
    file_server browse
    root  * /downloads
    basicauth {
      {{ range tree "caddy/config/basicauth_users/" -}}
        {{- .Key }} {{ .Value }}
      {{ end -}}
      }
}
EOH
        destination = "local/Caddyfile"
        change_mode = "restart"
      }

      resources {
        cpu    = 200
        memory = 512 
      }

      kill_timeout = "20s"
    }
  }
}
