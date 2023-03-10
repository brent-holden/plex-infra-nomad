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

    network {
      port "netbootxyz" {
        static = 3001
        to     = 3000
      }
      port "tftp" {
        static = 69
      }
      port "webconsole" {
        static = 8080
        to     = 80
      }
    }

    service {
      name = "netbootxyz"
      tags = ["infra", "http", "provisioning"]
      port = "netbootxyz"

      check {
        type     = "http"
        port     = "netbootxyz"
        path     = "/"
        interval = "30s"
        timeout  = "2s"

        check_restart {
          limit = 10000
          grace = "60s"
        }
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
        image = "docker.io/linuxserver/netbootxyz:latest"
        ports = [
          "netbootxyz",
          "tftp",
          "webconsole",
        ]
      }

      template {
        data        = <<-EOH
          IMAGE_DIGEST={{ keyOrDefault "netbootxyz/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "netbootxyz/config/release" "latest" }}
          EOH
        destination = "env_info"
        env         = true
      }

      resources {
        cpu    = 300
        memory = 1048
      }

      kill_timeout = "20s"
    }
  }
}
