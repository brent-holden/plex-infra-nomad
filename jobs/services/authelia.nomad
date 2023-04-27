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
        static = 9092
        to     = 9091
      }
      port "metrics_envoy" { to = 20200 }
    }

    service {
      name = "authelia"
      port = 9091

      meta {
        metrics_port_envoy = "${NOMAD_HOST_PORT_metrics_envoy}"
      }

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:20200"
            }
          }
        }
      }

      tags = [
        "traefik.enable=true",
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
        expose   = true

        check_restart {
          limit = 2
          grace = "30s"
        }
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
          "local/configuration.yml:/configuration.yml"
        ]
      }

      template {
        data        = <<-EOH
          AUTHELIA_JWT_SECRET={{ key "authelia/config/jwt_secret" }}
          AUTHELIA_SESSION_SECRET={{ key "authelia/config/session_secret" }}
          AUTHELIA_STORAGE_ENCRYPTION_KEY={{ key "authelia/config/encryption_key" }}
          EOH
        destination = "secrets/keys"
        env         = true
      }

      template {
        change_mode = "restart"
        data        = "{{ key \"authelia/config/users_database.yml\" }}"
        destination = "local/users_database.yml"
      }

      template {
        change_mode = "restart"
        data        = "{{ key \"authelia/config/configuration.yml\" }}"
        destination = "local/configuration.yml"
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "authelia/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "authelia/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "authelia/config/release" "latest" }}
          EOH
        destination = "local/env_info"
        env         = true
      }
    }
  }
}
