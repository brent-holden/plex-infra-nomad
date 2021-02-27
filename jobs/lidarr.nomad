job "lidarr" {
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

  group "lidarr" {
    count = 1

    restart {
      interval  = "12h"
      attempts  = 720
      delay     = "60s"
      mode      = "delay"
    }

    network {
      mode  = "bridge"
      port "lidarr" { static = 8686 }
    }

    service {
      name = "lidarr"
      tags = ["http","music"]
      port = "lidarr"

      check {
        type      = "http"
	      port      = "lidarr"
        path      = "/lidarr/login/"
        interval  = "30s"
        timeout   = "2s"

        check_restart {
          limit = 10000
          grace = "60s"
        }
      }
    }

    task "lidarr" {
      driver = "containerd-driver"

      env {
        PGID = "1100"
        PUID = "1100" 
      }

      config {
        image         = "docker.io/linuxserver/lidarr:${RELEASE}"

        mounts  = [
                    {
                      type    = "bind"
                      target  = "/config"
                      source  = "/opt/lidarr"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/downloads"
                      source  = "/mnt/downloads"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/music"
                      source  = "/mnt/rclone/media/Music"
                      options = ["rbind", "rw"]
                    }
                  ]
      }

      template {
        data          = "IMAGE_ID={{ keyOrDefault \"lidarr/config/image_id\" \"1\" }}\nRELEASE={{ keyOrDefault \"lidarr/config/release\" \"latest\" }}"
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 500
        memory = 2048
      }

      kill_timeout = "20s"
    }
  }
}
