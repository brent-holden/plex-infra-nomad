job "caddy" {
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

  group "caddy" {
    count = 1
    network {
      port "http"   { static = 80 }
      port "https"  { static = 443 }
    }

    service {
      name = "caddy"
      tags = ["https","request"]
      port = "https"

      check {
        type     = "tcp"
        port     = "https"
        interval = "60s"
        timeout  = "2s"
      }
    }

    ephemeral_disk {
      sticky  = true
      size    = 2048
    }

    task "caddy" {
      driver = "podman"

      config {
        image         = "docker://docker.io/caddy:${RELEASE}"
        network_mode  = "bridge"
        ports         = ["http", "https"]
        volumes       = ["/opt/caddy/config:/config","/opt/caddy/data:/data","/opt/caddy/Caddyfile:/etc/caddy/Caddyfile"]
      }

      template {
        data          = "IMAGE_ID={{ keyOrDefault \"caddy/config/image_id\" \"1\" }}\nRELEASE={{ keyOrDefault \"caddy/config/release\" \"latest\" }}"
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 100
        memory = 512 
      }

      kill_timeout = "20s"
    }
  }
}
