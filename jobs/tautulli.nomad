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

    ephemeral_disk {
      sticky = true
      size = 2048
    }

    task "tautulli" {
      driver = "podman"

      env {
        PGID  = "1100"
        PUID  = "1100"
        TZ    = "America/New_York"
      }

      config {
        image         = "docker://docker.io/linuxserver/tautulli:${RELEASE}"
        network_mode  = "bridge"
        ports         = ["tautulli"]
        volumes       = ["/opt/tautulli:/config","/opt/plex/Library/Application Support/Plex Media Server/Logs:/plex_logs"]
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
