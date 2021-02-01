job "lidarr" {
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

  group "lidarr" {
    count = 1
    network {
      port "lidarr" { static = 8686 }
    }

    service {
      name = "lidarr"
      tags = ["http","music"]
      port = "lidarr"

      check {
        type     = "tcp"
	      port     = "lidarr"
        interval = "60s"
        timeout  = "2s"
      }
    }

    ephemeral_disk {
      sticky  = true
      size    = 2048
    }

    task "lidarr" {
      driver = "podman"

      env {
        PGID = "1100"
        PUID = "1100" 
      }

      config {
        image         = "docker://docker.io/linuxserver/lidarr:${RELEASE}"
        network_mode  = "bridge"
        ports         = ["lidarr"]
        volumes       = ["/opt/lidarr:/config","/mnt/downloads:/downloads","/mnt/rclone/media/Music:/music"]
      }

      template {
        data          = "IMAGE_ID={{ key \"lidarr/config/image_id\" }}\nIMAGE={{ key \"lidarr/config/image\" }}\nRELEASE={{ key \"lidarr/config/release\" }}\nNOMAD_JOB_NAME={{ env \"NOMAD_JOB_NAME\" }}\n"
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
