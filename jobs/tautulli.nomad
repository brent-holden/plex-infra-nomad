job "tautulli" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  update {
    max_parallel = 1
    min_healthy_time = "5s"
    healthy_deadline = "2m"
    progress_deadline = "3m"
    auto_revert = true
    canary = 0
  }

  group "tautulli" {
    count = 1
    network {
      mode  = "bridge"
      port "tautulli" { static = 8181 }
    }

    service {
      name = "tautulli"
      tags = ["http","music"]
      port = "tautulli"

      check {
        type     = "tcp"
        port     = "tautulli"
        interval = "60s"
        timeout  = "2s"
      }
    }

    task "tautulli" {
      driver = "containerd-driver"

      env {
        PGID  = "1100"
        PUID  = "1100"
        TZ    = "America/New_York"
      }

      config {
        image         = "docker.io/linuxserver/tautulli:${RELEASE}"

        mounts  = [
                    {
                      type    = "bind"
                      target  = "/config"
                      source  = "/opt/tautulli"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/plex_logs"
                      source  = "/opt/plex/Library/Application Support/Plex Media Server/Logs"
                      options = ["rbind", "ro"]
                    }
                  ]
      }

      template {
        data          = "IMAGE_ID={{ keyOrDefault \"tautulli/config/image_id\" \"1\" }}\nRELEASE={{ keyOrDefault \"tautulli/config/release\" \"latest\" }}"
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 300
        memory = 512
      }

      kill_timeout = "20s"
    }
  }
}
