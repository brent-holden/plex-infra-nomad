job "backup-netbootxyz-assets" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "batch"

  periodic {
    cron             = "@daily"
    time_zone        = "America/New_York"
    prohibit_overlap = true
  }

  group "backup-netbootxyz" {
    count = 1

    volume "assets" {
      type      = "host"
      source    = "[[ .app.netbootxyz.volumes.assets.name ]]"
      read_only = true
    }

    task "unlock" {
      driver = "docker"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      template {
        data        = <<-EOH
          RESTIC_PASSWORD={{ key "restic/config/restic_password" }}
          EOH
        destination = "secrets/restic_password"
        env         = true
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "restic/config/image" }}
          RELEASE={{ keyOrDefault "restic/config/release" "latest" }}
          EOH
        destination = "local/env_info"
        env         = true
      }

      config {
        image = "${IMAGE}:${RELEASE}"

        args = [
          "--repo", "rest:[[ .app.rclone_restic.service_url ]]:[[ .app.rclone_restic.ports.rclone ]]/netbootxyz/assets",
          "unlock",
        ]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }

    task "backup" {
      driver = "docker"

      volume_mount {
        volume      = "assets"
        destination = "/assets"
      }

      template {
        data        = <<-EOH
          RESTIC_PASSWORD={{ key "restic/config/restic_password" }}
          EOH
        destination = "secrets/restic_password"
        env         = true
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "restic/config/image" }}
          RELEASE={{ keyOrDefault "restic/config/release" "latest" }}
          EOH
        destination = "local/env_info"
        env         = true
      }

      config {
        image = "${IMAGE}:${RELEASE}"

        args = [
          "--repo", "rest:[[ .app.rclone_restic.service_url ]]:[[ .app.rclone_restic.ports.rclone ]]/netbootxyz/assets",
          "backup",
          "/assets",
        ]
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }

    task "prune" {
      driver = "docker"

      lifecycle {
        hook    = "poststop"
        sidecar = false
      }

      template {
        data        = <<-EOH
          RESTIC_PASSWORD={{ key "restic/config/restic_password" }}
          EOH
        destination = "secrets/restic_password"
        env         = true
      }

      template {
        data        = <<-EOH
          IMAGE={{ key "restic/config/image" }}
          RELEASE={{ keyOrDefault "restic/config/release" "latest" }}
          EOH
        destination = "local/env_info"
        env         = true
      }

      config {
        image = "${IMAGE}:${RELEASE}"

        args = [
          "--repo", "rest:[[ .app.rclone_restic.service_url ]]:[[ .app.rclone_restic.ports.rclone ]]/netbootxyz/assets",
          "forget",
          "--keep-last", "30",
          "--keep-monthly", "12",
          "--prune",
        ]
      }

      resources {
        cpu    = 300
        memory = 512
      }
    }
  }
}
