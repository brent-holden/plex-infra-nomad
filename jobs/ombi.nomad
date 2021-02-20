job "ombi" {
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

  group "ombi" {
    count = 1
    network {
      mode = "bridge"
      port "ombi" { static = 3579 }
    }

    service {
      name = "ombi"
      tags = ["http","request"]
      port = "ombi"

      check {
        type     = "tcp"
        port     = "ombi"
        interval = "30s"
        timeout  = "2s"
      }
    }

    task "ombi" {
      driver = "containerd-driver"

      env {
       PGID = "1100"
       PUID = "1100"
       TZ   = "America/New_York"
      }

      config {
        image         = "docker.io/linuxserver/ombi:${RELEASE}"
        mounts  = [
                    {
                      type    = "bind"
                      target  = "/config"
                      source  = "/opt/ombi"
                      options = ["rbind", "rw"]
                    }
                  ]
      }

      template {
        data          = "IMAGE_ID={{ keyOrDefault \"ombi/config/image_id\" \"1\" }}\nRELEASE={{ keyOrDefault \"ombi/config/release\" \"latest\" }}"
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 100
        memory = 2048
      }

      kill_timeout = "20s"
    }
  }
}
