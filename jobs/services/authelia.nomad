job "authelia" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"

  constraint {
    attribute = "${meta.network_node}"
    value     = "true"
  }

  group "authelia" {
    count = 1

    network {
      mode = "bridge"
      port "authelia" {
        static = 9091
      }
    }

    service {
      name = "authelia"
      port = 9091

      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=false",
        "traefik.http.services.authelia.loadbalancer.server.port=${NOMAD_HOST_PORT_authelia}",
        "traefik.http.routers.authelia.rule=Host(`[[ .app.authelia.traefik.hostname ]].[[ .app.traefik.domain.tld ]]`) && PathPrefix(`[[ .app.authelia.traefik.path ]]`)",
        "traefik.http.routers.authelia.entrypoints=[[ .app.authelia.traefik.entrypoints ]]",
        "traefik.http.middlewares.authelia.forwardauth.address=[[ .app.authelia.traefik.forwardauth.address ]]",
        "traefik.http.middlewares.authelia.forwardauth.trustForwardHeader=[[ .app.authelia.traefik.forwardauth.trustforwardheader ]]",
        "traefik.http.middlewares.authelia.forwardauth.authResponseHeaders=[[ .app.authelia.traefik.forwardauth.authresponseheaders ]]",
      ]

      check {
        name     = "authelia"
        type     = "http"
        port     = "authelia"
        path     = "/api/health"
        interval = "30s"
        timeout  = "2s"
      }
    }

    volume "config" {
      type      = "host"
      source    = "authelia-config"
      read_only = false
    }

    update {
      max_parallel = 0
      health_check = "checks"
      auto_revert  = true
    }

    task "authelia" {
      driver = "docker"

      volume_mount {
        volume      = "config"
        destination = "/config"
        read_only   = false
      }

      env {
        TZ = "America/New_York"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["authelia"]

        volumes = [
          "local/configuration.yml:/config/configuration.yml"
        ]
      }

      template {
        data        = <<-EOH
          AUTHELIA_JWT_SECRET={{ key "authelia/config/jwt_secret" }}
          AUTHELIA_SESSION_SECRET={{ key "authelia/config/session_secret" }}
          AUTHELIA_STORAGE_ENCRYPTION_KEY={{ key "authelia/config/encryption_key" }}
          AUTHELIA_NOTIFIER_SMTP_PASSWORD={{ key "authelia/config/smtp_password" }}
          EOH
        destination = "secrets/keys"
        env         = true
      }

      template {
        change_mode = "restart"
        data        = "{{ key \"authelia/config/users_database.yml\" }}"
        destination = "secrets/users_database.yml"
      }

      template {
        change_mode = "restart"
        data        = "{{ key \"authelia/config/configuration.yml\" }}"
        destination = "local/configuration.yml"
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "authelia/config/image" }}
          RELEASE={{ key "authelia/config/release" }}
          IMAGE_DIGEST={{ keyOrDefault "authelia/config/image_digest" "1" }}
          EOH
        destination = "local/env_info"
        env         = true
      }
    }
  }
}
