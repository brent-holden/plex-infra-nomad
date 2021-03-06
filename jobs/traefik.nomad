job "traefik" {
  datacenters = ["lab"]
  type        = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }
  group "traefik" {
    count = 1

    network {
      port "web" { static = 80 }
      port "web-secure" { static = 443 }
      port "traefik" { static = 8081 }
    }

    task "traefik" {
      driver = "containerd-driver"

      service {
        name = "traefik"
        port = "web-secure"

        tags = [
          "traefik.enable=true",
          "traefik.http.services.traefik.loadbalancer.server.port=80",
          "traefik.http.routers.traefik.rule=Host(`${ACME_HOST}`) && Path(`/`)",
          "traefik.http.routers.traefik.middlewares=redirect-root-ombi",
          "traefik.http.middlewares.redirect-root-ombi.redirectregex.regex=.*",
          "traefik.http.middlewares.redirect-root-ombi.redirectregex.replacement=/ombi",
        ]

        check {
          name     = "alive"
          type     = "tcp"
          port     = "web-secure"
          interval = "10s"
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
        host_network  = true
        image         = "docker.io/library/traefik:${RELEASE}"
        command       = "traefik"

        args    = [
                    "--api",
                    "--api.dashboard",
                    "--api.insecure",
                    "--log",
                    "--log.level=INFO",
                    "--accesslog",
                    "--accesslog.filepath=logs/access.log",
                    "--entrypoints.web.address=:80",
                    "--entrypoints.web.forwardedheaders.insecure=true",
                    "--entrypoints.web.http.redirections.entryPoint.to=web-secure",
                    "--entrypoints.web.http.redirections.entryPoint.scheme=https",
                    "--entrypoints.web.http.redirections.entrypoint.permanent=true",
                    "--entrypoints.web-secure.address=:443",
                    "--entrypoints.web-secure.http.tls=true",
                    "--entrypoints.web-secure.http.tls.certresolver=letsencrypt",
                    "--entrypoints.web-secure.http.tls.domains=${ACME_HOST}",
                    "--entrypoints.traefik.address=:8081",
                    "--certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL}",
                    "--certificatesresolvers.letsencrypt.acme.storage=/etc/traefik/acme.json",
                    "--certificatesresolvers.letsencrypt.acme.caserver=https://acme-v02.api.letsencrypt.org/directory",
                    "--certificatesresolvers.letsencrypt.acme.httpchallenge=true",
                    "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web",
                    "--providers.consulcatalog=true",
                    "--providers.consulcatalog.prefix=traefik",
                    "--providers.consulcatalog.exposedbydefault=false",
                    "--providers.consulcatalog.endpoint.address=127.0.0.1:8500",
                    "--providers.consulcatalog.endpoint.scheme=http",
                  ]

        mounts  = [
                    {
                      type    = "bind"
                      target  = "/etc/traefik"
                      source  = "/opt/traefik/config"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/logs"
                      source  = "/opt/traefik/logs"
                      options = ["rbind", "rw"]
                    }
                  ]
      }

      template {
        data          = <<EOH
IMAGE_DIGEST={{ keyOrDefault "traefik/config/image_digest" "1" }}
RELEASE={{ keyOrDefault "traefik/config/release" "latest" }}
ACME_EMAIL={{ key "traefik/config/acme_email" }}
ACME_HOST={{ key "traefik/config/acme_host" }}
EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
