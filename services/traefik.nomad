job "traefik" {
  datacenters = ["[[ .nomad.datacenter ]]"]
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
      port "websecure" { static = 443 }
      port "traefik" { static = 8081 }
      port "metrics" { static = 8082 }
    }

    volume "certs" {
      type      = "host"
      read_only = false
      source    = "traefik-certs"
    }

    update {
      max_parallel = 0
      health_check = "checks"
      auto_revert  = true
    }

    service {
      name = "traefik"
      port = "websecure"
      task = "traefik"

      connect {
        native = true
      }

      tags = [
      ]

      check {
        name     = "traefik"
        type     = "http"
        port     = "traefik"
        path     = "/ping"
        interval = "30s"
        timeout  = "2s"

        check_restart {
          limit = 2
          grace = "30s"
        }
      }
    }

    task "traefik" {
      driver = "docker"

      volume_mount {
        volume      = "certs"
        destination = "/certs"
      }

      config {
        image   = "${IMAGE}:${RELEASE}"
        command = "traefik"
        ports = ["web",
          "websecure",
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
          "--entrypoints.web.http.redirections.entrypoint.to=websecure",
          "--entrypoints.web.http.redirections.entrypoint.scheme=https",
          "--entrypoints.websecure.address=:443",
          "--entrypoints.websecure.http.tls.certresolver=letsencrypt",
          "--entrypoints.websecure.http.tls.domains[0].main=[[ .app.traefik.domain.tld ]]",
          "--entrypoints.websecure.http.tls.domains[0].sans=*.[[ .app.traefik.domain.tld ]]",
          "--certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL}",
          "--certificatesresolvers.letsencrypt.acme.storage=/certs/acme.json",
          #          "--certificatesresolvers.letsencrypt.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory",
          "--certificatesresolvers.letsencrypt.acme.caserver=https://acme-v02.api.letsencrypt.org/directory",
          "--certificatesresolvers.letsencrypt.acme.dnschallenge=true",
          "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare",
          "--providers.consulcatalog=true",
          "--providers.consulcatalog.prefix=traefik",
          "--providers.consulcatalog.connectaware=true",
          "--providers.consulcatalog.connectbydefault=true",
          "--providers.consulcatalog.exposedbydefault=false",
          "--providers.consulcatalog.endpoint.address=consul.service.consul:8500",
          "--providers.consulcatalog.endpoint.scheme=http",
          "--entrypoints.traefik.address=:8081",
          "--ping=true",
          "--metrics.prometheus=true",
          "--entrypoints.metrics.address=:8082",
          "--metrics.prometheus.entrypoint=metrics",
          "--metrics.prometheus.buckets=0.100000, 0.300000, 1.200000, 5.000000",
          "--metrics.prometheus.addentrypointslabels=true",
          "--metrics.prometheus.addrouterslabels=true",
          "--metrics.prometheus.addserviceslabels=true",
        ]

      }

      template {
        data        = <<-EOH
          IMAGE={{ key "traefik/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "traefik/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "traefik/config/release" "latest" }}
          EOH
        destination = "local/env_info"
        env         = true
      }

      template {
        data        = <<-EOH
          ACME_EMAIL={{ key "traefik/config/acme_email" }}
          CLOUDFLARE_EMAIL={{ key "traefik/config/acme_email" }}
          CLOUDFLARE_DNS_API_TOKEN={{ key "traefik/config/dns_api_token" }}
          EOH
        destination = "secrets/cloudflare"
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
