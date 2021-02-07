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
      port "sabnzbd" { static = 8080 }
    }

    service {
      name = "sabnzbd"
      tags = ["http","downloader"]
      port = "sabnzbd"

      check {
        type     = "tcp"
        port     = "sabnzbd"
        interval = "60s"
        timeout  = "2s"
      }
    }

    ephemeral_disk {
      sticky  = true
      size    = 2048
    }

    task "sabnzbd" {
      driver = "podman"

      env {
        PGID = "1100"
        PUID = "1100" 
      }

      config {
        image         = "docker://docker.io/linuxserver/sabnzbd:${RELEASE}"
        network_mode  = "bridge"
        ports         = ["sabnzbd"]
        volumes       = ["/opt/sabnzbd:/config","/mnt/downloads:/downloads"]
      }

      template {
        data          = "IMAGE_ID={{ keyOrDefault \"sabnzbd/config/image_id\" \"1\" }}\nRELEASE={{ keyOrDefault \"sabnzbd/config/release\" \"latest\" }}"
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 2000
        memory = 4096
      }

      kill_timeout = "20s"
    }
  }
}
