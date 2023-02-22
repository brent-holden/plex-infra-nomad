job "traefik" {
  datacenters = ["lab"]
  type        = "service"
  priority    = 10

  constraint {
    attribute = "${meta.network_node}"
    value     = "true"
  }

  group "traefik" {
    count = 1

    network {
      mode = "bridge"
      port "web" { static = 80 }
      port "web-secure" { static = 443 }
      port "traefik" { static = 8081 }
      port "metrics" { static = 8082 }
    }

    service {
      name = "traefik"
      port = "web-secure"

      connect {
        native = true
      }

      tags =  [
              ]

      check {
        name     = "alive"
        type     = "tcp"
        port     = "traefik"
        interval = "10s"
        timeout  = "2s"

        check_restart {
          limit = 2
          grace = "10s"
        }
      }
    }

    ephemeral_disk {
      size    = 300
      sticky  = true
      migrate = true
    }

    update {
      max_parallel = 0
      health_check = "checks"
      auto_revert  = true
    }

    task "traefik" {
      driver = "docker"

      config {
        image   = "${IMAGE}:${RELEASE}"
        command = "traefik"
        ports = [
          "web",
          "web-secure",
          "traefik",
          "metrics",
        ]

        args = [
          "--api.dashboard",
          "--api.insecure",
          "--log.level=DEBUG",
          "--accesslog",
          "--accesslog.filepath=logs/access.log",
          "--entrypoints.web.address=:80",
          "--entrypoints.web.http.redirections.entrypoint.to=web-secure",
          "--entrypoints.web.http.redirections.entrypoint.scheme=https",
          "--entrypoints.web-secure.address=:443",
          "--entrypoints.web-secure.http.tls.certresolver=letsencrypt",
          "--entrypoints.web-secure.http.tls.domains[0].main=${ACME_DOMAIN}",
          "--entrypoints.web-secure.http.tls.domains[0].sans=*.${ACME_DOMAIN}",
          "--certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL}",
          "--certificatesresolvers.letsencrypt.acme.storage=local/acme.json",
#          "--certificatesresolvers.letsencrypt.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory",
          "--certificatesresolvers.letsencrypt.acme.caserver=https://acme-v02.api.letsencrypt.org/directory",
          "--certificatesresolvers.letsencrypt.acme.dnschallenge=true",
          "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare",
          "--providers.consulcatalog=true",
          "--providers.consulcatalog.prefix=traefik",
          "--providers.consulcatalog.connectaware=true",
          "--providers.consulcatalog.connectbydefault=true",
          "--providers.consulcatalog.exposedbydefault=false",
          "--providers.consulcatalog.endpoint.address=192.168.0.2:8500",
          "--providers.consulcatalog.endpoint.scheme=http",
          "--entrypoints.traefik.address=:8081",
          "--metrics.prometheus=true",
          "--entrypoints.metrics.address=:8082",
          "--metrics.prometheus.entrypoint=metrics",
          "--metrics.prometheus.buckets=0.100000, 0.300000, 1.200000, 5.000000",
          "--metrics.prometheus.addentrypointslabels=true",
          "--metrics.prometheus.addrouterslabels=true",
          "--metrics.prometheus.addserviceslabels=true",
          "--pilot.token=${PILOT_TOKEN}",
        ]

      }

      template {
        data        = <<-EOH
          IMAGE={{ key "traefik/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "traefik/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "traefik/config/release" "latest" }}
          ACME_EMAIL={{ key "traefik/config/acme_email" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
          ACME_DOMAIN={{ key "traefik/config/acme_domain" }}
          PILOT_TOKEN={{ key "traefik/config/pilot_token" }}
          CLOUDFLARE_EMAIL={{ key "traefik/config/acme_email" }}
          CLOUDFLARE_DNS_API_TOKEN={{ key "traefik/config/dns_api_token" }}
          EOH
        destination = "env_info"
        env         = true
      }

      resources {
        cpu    = 100
        memory = 256
      }

      restart {
        interval = "12h"
        attempts = 720
        delay    = "60s"
        mode     = "delay"
      }
    }
  }
}
