job "plex" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"
  priority    = 20

  group "plex" {
    count = 1

    network {
      port "plex" { static = 32400 }
    }

    service {
      name = "plex"
      port = 32400

      connect {
        native = true
      }

      tags = ["media"]

      check {
        type     = "http"
        protocol = "https"
        tls_skip_verify = true
        port     = "plex"
        path     = "/identity"
        interval = "1m"
        timeout  = "2s"
        header {
          Accept = ["application/json"]
        }
      }

    }

    volume "config" {
      type   = "host"
      source = "plex-config"
    }

    volume "transcode" {
      type   = "host"
      source = "plex-transcoder"
    }

    volume "media" {
      type      = "host"
      source    = "media-base"
      read_only = true
    }

    update {
      max_parallel = 0
      health_check = "checks"
      auto_revert  = true
    }

    task "plex" {
      driver = "docker"

      env {
        PLEX_UID   = "[[ .common.env.puid ]]"
        PLEX_GID   = "[[ .common.env.pgid ]]"
        VERSION    = "docker"
        TZ         = "America/New_York"
        PLEX_CLAIM = "${PLEX_CLAIM}"
      }

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      volume_mount {
        volume      = "transcode"
        destination = "/transcode"
      }

      volume_mount {
        volume      = "media"
        destination = "/media"
        read_only   = true
      }

      config {
        image        = "${IMAGE}:${RELEASE}"
        network_mode = "host"
        privileged   = true
        devices = [
          {
            host_path      = "/dev/dri"
            container_path = "/dev/dri"
          }
        ]

      }

      template {
        data        = <<-EOH
          IMAGE={{ key "plex/config/image" }}
          RELEASE={{ key "plex/config/release" }}
          VERSION={{ keyOrDefault "plex/config/version" "1.0" }}
          EOH
        destination = "local/env_info"
        env         = true
      }

      template {
        data        = <<-EOH
          PLEX_CLAIM={{ keyOrDefault "plex/config/claim_token" "claim-XXXXX" }}
          EOH
        destination = "secrets/plex_claim"
        env         = true
      }

      resources {
        cpu    = 24000
        memory = 32768
      }

      restart {
        interval = "12h"
        attempts = 720
        delay    = "60s"
        mode     = "delay"
      }

      kill_timeout = "30s"
    }
  }
}
