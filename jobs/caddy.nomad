job "caddy" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  update {
    max_parallel      = 1
    min_healthy_time  = "30s"
    healthy_deadline  = "1m"
    progress_deadline = "3m"
    auto_revert       = true
    canary            = 0
  }

  group "caddy" {
    count = 1
    network {
      port "http"   { static  = 80 }
      port "https"  { static  = 443 }
    }

    service {
      name = "caddy"
      tags = ["https","request"]
      port = "https"

      check {
        type     = "tcp"
        port     = "https"
        interval = "60s"
        timeout  = "5s"
      }
    }

    task "caddy" {
      driver = "containerd-driver"

      config {
        image         = "docker.io/library/caddy:${RELEASE}"
        host_network  = true
        cap_add       = ["CAP_NET_BIND_SERVICE"]

        mounts  = [
                    {
                      type    = "bind"
                      target  = "/config"
                      source  = "/opt/caddy/config"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/data"
                      source  = "/opt/caddy/data"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/etc/caddy/Caddyfile"
                      source  = "/opt/caddy/Caddyfile"
                      options = ["rbind", "rw"]
                    }
                  ]
      }

      template {
        data          = "IMAGE_ID={{ keyOrDefault \"caddy/config/image_id\" \"1\" }}\nRELEASE={{ keyOrDefault \"caddy/config/release\" \"latest\" }}"
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 200
        memory = 512 
      }

      kill_timeout = "20s"
    }
  }
}
