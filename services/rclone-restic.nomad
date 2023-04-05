job "rclone_restic" {
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

  group "rclone_restic" {
    count = 1

    network {
      port "rclone" { static = 7070 }
      port "rclone_web" { static = 7071 }
    }

    service {
      name = "rclone-restic"
      tags = ["infra", "rest", "backup"]
      port = "rclone"

      check {
        type     = "http"
        port     = "rclone_web"
        path     = "/"
        interval = "30s"
        timeout  = "2s"

        check_restart {
          limit = 100
          grace = "60s"
        }
      }
    }

    restart {
      interval = "12h"
      attempts = 720
      delay    = "60s"
      mode     = "delay"
    }

    volume "cache" {
      type   = "host"
      source = "rclone-cache-backup"
    }

    task "rclone" {
      driver = "docker"

      volume_mount {
        volume      = "cache"
        destination = "/cache"
      }

      config {
        image = "${IMAGE}:${RELEASE}"
        ports = ["rclone", "rclone_web"]

        privileged = true
        cap_add    = ["sys_admin"]

        devices = [
          {
            host_path      = "/dev/fuse"
            container_path = "/dev/fuse"
          }
        ]

        args = [
          "serve",
          "restic",
          "google-drive:Backups",
          "--addr", ":7070",
          "--cache-dir", "/cache",
          "--rc",
          "--rc-no-auth", 
          "--rc-web-gui",
          "--rc-enable-metrics",
          "--rc-addr", ":7071",
          "--rc-web-gui-no-open-browser",
        ]

        volumes = [
          "local/rclone.conf:/config/rclone/rclone.conf",
        ]

      }

      template {
        change_mode = "restart"
        data        = "{{ key \"rclone/config/rclone.conf\" }}"
        destination = "local/rclone.conf"
      }

      template {
        change_mode = "restart"
        data        = <<-EOH
          IMAGE={{ key "rclone/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "rclone/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "rclone/config/release" "latest" }}
          EOH
        destination = "local/env_info"
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
