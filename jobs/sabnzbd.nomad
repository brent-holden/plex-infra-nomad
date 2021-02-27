job "sabnzbd" {
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

  group "sabnzbd" {
    count = 1
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
        data          = "IMAGE_ID={{ keyOrDefault \"sabnzbd/config/image_id\" \"1\" }}\nRELEASE={{ keyOrDefault \"sabnzbd/config/release\" \"latest\" }}"
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
