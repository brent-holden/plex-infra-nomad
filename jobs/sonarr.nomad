job "sonarr" {
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

  group "sonarr" {
    count = 1
    network {
      mode  = "bridge"
      port "sonarr" { static = 8989 }
    }

    service {
      name = "sonarr"
      tags = ["http","music"]
      port = "sonarr"

      check {
        type      = "http"
        port      = "sonarr"
        path      = "/sonarr/login"
        interval  = "30s"
        timeout   = "2s"
      }
    }

    task "sonarr" {
      driver = "containerd-driver"

      env {
        PGID  = "1100"
        PUID  = "1100"
        TZ    = "America/New_York"
      }

      config {
        image   = "docker.io/linuxserver/sonarr:${RELEASE}"
        mounts  = [
                    {
                      type    = "bind"
                      target  = "/config"
                      source  = "/opt/sonarr"
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
                      target  = "/tv"
                      source  = "/mnt/rclone/media/TV"
                      options = ["rbind", "rw"]
                    }
                  ]
      }

      template {
        data          = "IMAGE_ID={{ keyOrDefault \"sonarr/config/image_id\" \"1\" }}\nRELEASE={{ keyOrDefault \"sonarr/config/release\" \"latest\" }}"
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
