job "prune-downloads" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "batch"

  periodic {
    cron             = "5 5 * * * *"
    time_zone        = "America/New_York"
    prohibit_overlap = true
  }

  group "prune-downloads" {
    count = 1

    volume "downloads" {
      type   = "host"
      source = "downloads"
      read_only = false
    }

    task "prune" {
      driver = "exec"

      user = "[[ .common.env.user ]]"

      volume_mount {
        volume      = "downloads"
        destination = "/downloads"
        read_only = false
      }

      config {
        command = "/bin/bash"
        args = ["local/prune_downloads.sh"]
      }

      template {
        destination = "local/prune_downloads.sh"
        perms = "755"
        data        = <<-EOH
          #!/usr/bin/env bash
          echo "Let's prune some downloads!"
          find /downloads -mindepth 2 -mtime +3 -print -exec rm -rf {} \;
          echo "All done. Exiting"
          EOH
      }
    }
  }
}
