job "netbootxyz" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"

  constraint {
    attribute = "${meta.network_node}"
    value     = "true"
  }

  update {
    max_parallel = 0
    health_check = "checks"
    auto_revert  = true
  }

  group "netbootxyz" {
    count = 1

    restart {
      interval = "12h"
      attempts = 720
      delay    = "60s"
      mode     = "delay"
    }

    service {
      name = "netbootxyz"
      tags = ["infra", "http", "provisioning"]
      port = "3000"

      check {
        type     = "http"
        port     = "3000"
        path     = "/"
        interval = "30s"
        timeout  = "2s"
      }
    }

    volume "config" {
      type      = "host"
      read_only = false
      source    = "netbootxyz-config"
    }

    volume "assets" {
      type      = "host"
      read_only = false
      source    = "netbootxyz-assets"
    }

    task "netbootxyz" {
      driver = "docker"

      env {
        PGID = "1000"
        PUID = "1000"
      }

      volume_mount {
        volume      = "config"
        destination = "/config"
        read_only   = false
      }

      volume_mount {
        volume      = "assets"
        destination = "/assets"
        read_only   = false
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        network_mode = "host"
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "netbootxyz/config/image" }}
          RELEASE={{ key "netbootxyz/config/release" }}
          IMAGE_DIGEST={{ keyOrDefault "netbootxyz/config/image_digest" "1" }}
          EOH
        destination = "local/env_info"
        env         = true
      }

      kill_timeout = "20s"
    }
  }
}
