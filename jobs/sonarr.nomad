job "sonarr" {
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

  group "sonarr" {
    count = 1
    network {
      port "sonarr" {
        static = 8989
      }
    }

    service {
      name = "sonarr"
      tags = ["http","music"]
      port = "sonarr"

      check {
        type     = "tcp"
	port     = "sonarr"
        interval = "60s"
        timeout  = "2s"
      }
    }

    ephemeral_disk {
      sticky = true
      size = 2048
    }

    task "sonarr" {
      driver = "podman"

      env {
        PGID = "1100"
        PUID = "1100" 
      }

      config {
        image = "docker://linuxserver/sonarr:preview"
        network_mode = "bridge"
        ports = ["sonarr"]
        volumes = ["/opt/sonarr:/config","/mnt/downloads:/downloads","/mnt/rclone/media/TV:/tv","/etc/localtime:/etc/localtime"]
      }

      template {
        data = <<EOF
IMAGE_ID={{ key "sonarr/config/image_id" }}
EOF

        destination = "image_id.env"
        env = true
      }

      resources {
        cpu    = 500
        memory = 2048
      }

      kill_timeout = "20s"
    }
  }
}
