job "ombi" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  update {
    max_parallel  = 0
    health_check  = "checks"
    auto_revert   = true
  }

  group "ombi" {
    count = 1

    restart {
      interval  = "12h"
      attempts  = 720
      delay     = "60s"
      mode      = "delay"
    }

    network {
      mode = "bridge"
      port "ombi" { static = 3579 }
    }

    service {
      name = "ombi"
      tags = ["http","request"]
      port = "ombi"

      check {
        type      = "http"
        port      = "ombi"
        path      = "/"
        interval  = "30s"
        timeout   = "2s"

        check_restart {
          limit = 10000
          grace = "60s"
        }
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
