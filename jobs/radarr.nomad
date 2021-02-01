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
      port "radarr" { static = 7878 }
    }

    service {
      name = "radarr"
      tags = ["http","music"]
      port = "radarr"

      check {
        type     = "tcp"
        port     = "radarr"
        interval = "60s"
        timeout  = "2s"
      }
    }

    ephemeral_disk {
      sticky = true
      size = 2048
    }

    task "radarr" {
      driver = "podman"

      env {
        PGID = "1100"
        PUID = "1100" 
      }

      config {
        image         = "docker://linuxserver/radarr:latest"
        network_mode  = "bridge"
        ports         = ["radarr"]
        volumes       = ["/opt/radarr:/config","/mnt/downloads:/downloads","/mnt/rclone/media/Movies:/media/movies","/etc/localtime:/etc/localtime:ro"]
      }

      template {
        data          = "IMAGE_ID={{ key \"radarr/config/image_id\" }}"
        destination   = "image_id.env"
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
