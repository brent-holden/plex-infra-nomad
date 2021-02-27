job "radarr" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  update {
    max_parallel      = 1
    min_healthy_time  = "5s"
    healthy_deadline  = "2m"
    progress_deadline = "3m"
    auto_revert       = true
    canary            = 0
  }

  group "radarr" {
    count = 1
    network {
      mode  = "bridge"
      port "radarr" { static = 7878 }
    }

    service {
      name = "radarr"
      tags = ["http","music"]
      port = "radarr"

      check {
        type      = "http"
        port      = "radarr"
        path      = "/radarr/login"
        interval  = "30s"
        timeout   = "2s"
      }
    }

    ephemeral_disk {
      sticky = true
      size = 2048
    }

    task "radarr" {
      driver = "containerd-driver"

      env {
        PGID  = "1100"
        PUID  = "1100" 
        TZ    = "America/New_York"
      }

      config {
        image   = "docker.io/linuxserver/radarr:${RELEASE}"

        mounts  = [
                    {
                      type    = "bind"
                      target  = "/config"
                      source  = "/opt/radarr"
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
                      target  = "/media/movies"
                      source  = "/mnt/rclone/media/Movies"
                      options = ["rbind", "rw"]
                    }
                  ]
      }

      template {
        data          = "IMAGE_ID={{ keyOrDefault \"radarr/config/image_id\" \"1\" }}\nRELEASE={{ keyOrDefault \"radarr/config/release\" \"latest\" }}"
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
