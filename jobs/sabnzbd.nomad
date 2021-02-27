job "sabnzbd" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  update {
    max_parallel  = 0
    health_check  = "checks"
    auto_revert   = true
  }

  group "sabnzbd" {
    count = 1

    restart {
      interval  = "12h"
      attempts  = 720
      delay     = "60s"
      mode      = "delay"
    }

    network {
      mode = "bridge"
      port "sabnzbd" { static = 8080 }
    }

    service {
      name = "sabnzbd"
      tags = ["http","downloader"]
      port = "sabnzbd"

      check {
        type      = "http"
        port      = "sabnzbd"
        path      = "/sabnzbd/login/"
        interval  = "30s"
        timeout   = "2s"

        check_restart {
          limit = 10000
          grace = "60s"
        }
      }
    }

    task "sabnzbd" {
      driver = "containerd-driver"

      env {
        PGID = "1100"
        PUID = "1100" 
      }

      config {
        image   = "docker.io/linuxserver/sabnzbd:${RELEASE}"

        mounts  = [
                    {
                      type    = "bind"
                      target  = "/config"
                      source  = "/opt/sabnzbd"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/downloads"
                      source  = "/mnt/downloads"
                      options = ["rbind", "rw"]
                    }
                  ]
      }

      template {
        data          = <<EOH
IMAGE_ID={{ keyOrDefault "sabnzbd/config/image_id" "1" }}
RELEASE={{ keyOrDefault "sabnzbd/config/release" "latest" }}
EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 4000
        memory = 16384
      }

      kill_timeout = "20s"
    }
  }
}
