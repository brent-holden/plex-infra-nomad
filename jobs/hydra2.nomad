job "hydra2" {
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

  group "hydra2" {
    count = 1

    restart {
      interval  = "12h"
      attempts  = 720
      delay     = "60s"
      mode      = "delay"
    }

    network {
      mode = "bridge"
      port "hydra2" {
        static = 5076
      }
    }

    service {
      name = "hydra2"
      tags = ["http","index"]
      port = "hydra2"

      check {
        type      = "http"
        port      = "hydra2"
        path      = "/hydra2/login.html"
        interval  = "30s"
        timeout   = "2s"

        check_restart {
          limit = 10000
          grace = "60s"
        }
      }
    }

    task "hydra2" {
      driver = "containerd-driver"

      env {
       PGID = "1100"
       PUID = "1100"
      }

      config {
        image   = "docker.io/linuxserver/nzbhydra2:${RELEASE}"
        mounts  = [
                    {
                      type    = "bind"
                      target  = "/config"
                      source  = "/opt/hydra2"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/downloads"
                      source  = "/mnt/downloads"
                      options = ["rbind", "rw"]
                    }
                  ]
      }

      template {
        data          = "IMAGE_ID={{ keyOrDefault \"hydra2/config/image_id\" \"1\" }}\nRELEASE={{ keyOrDefault \"hydra2/config/release\" \"latest\" }}"
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 1000
        memory = 2048
      }

      kill_timeout = "20s"
    }
  }
}
