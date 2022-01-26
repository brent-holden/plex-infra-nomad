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
      mode = "bridge"
      port "web" { static = 80 }
      port "web-secure" { static = 443 }
      port "traefik" { static = 8081 }
    }

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    task "traefik" {
      driver = "docker"

      service {
        name = "traefik"
        port = "web-secure"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.traefik.rule=Host(`${ACME_HOST}`)",
          "traefik.http.routers.traefik.tls=true",
          "traefik.http.routers.traefik.tls.certresolver=letsencrypt",
          "traefik.http.routers.traefik.middlewares=redirect-root-ombi",
          "traefik.http.middlewares.redirect-root-ombi.redirectregex.regex=.*",
          "traefik.http.middlewares.redirect-root-ombi.redirectregex.replacement=/ombi",
          "traefik.http.middlewares.redirect-root-ombi.redirectregex.permanent=true",
        ]

        check {
          name     = "alive"
          type     = "tcp"
          port     = "web-secure"
          interval = "10s"
          timeout  = "2s"

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

      config {
        image         = "${IMAGE}:${RELEASE}"
        command       = "traefik"
        ports         = [
                          "web",
                          "web-secure",
                          "traefik"
                        ]

        args    = [
                    "--api",
                    "--api.dashboard",
                    "--api.insecure",
                    "--log",
                    "--log.level=INFO",
                    "--accesslog",
                    "--accesslog.filepath=logs/access.log",
                    "--entrypoints.traefik.address=:8081",
                    "--entrypoints.web.address=:80",
                    "--entrypoints.web.forwardedheaders.insecure=true",
                    "--entrypoints.web.http.redirections.entryPoint.to=web-secure",
                    "--entrypoints.web.http.redirections.entryPoint.scheme=https",
                    "--entrypoints.web.http.redirections.entrypoint.permanent=true",
                    "--entrypoints.web-secure.address=:443",
                    "--entrypoints.web-secure.http.tls.certresolver=letsencrypt",
                    "--certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL}",
                    "--certificatesresolvers.letsencrypt.acme.storage=/etc/traefik/acme.json",
                    "--certificatesresolvers.letsencrypt.acme.caserver=https://acme-v02.api.letsencrypt.org/directory",
                    "--certificatesresolvers.letsencrypt.acme.httpchallenge=true",
                    "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web",
                    "--providers.consulcatalog=true",
                    "--providers.consulcatalog.prefix=traefik",
                    "--providers.consulcatalog.exposedbydefault=false",
                    "--providers.consulcatalog.endpoint.address=consul.service.consul:8500",
                    "--providers.consulcatalog.endpoint.scheme=http",
                    "--pilot.token=${PILOT_TOKEN}",
                  ]

        mount {
          type      = "bind"
          target    = "/etc/traefik"
          source    = "/opt/traefik/config"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type      = "bind"
          target    = "/logs"
          source    = "/opt/traefik/logs"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

      }

      template {
        data          = <<-EOH
          IMAGE={{ key "traefik/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "traefik/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "traefik/config/release" "latest" }}
          ACME_EMAIL={{ key "traefik/config/acme_email" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
          PILOT_TOKEN={{ key "traefik/config/pilot_token" }}
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
