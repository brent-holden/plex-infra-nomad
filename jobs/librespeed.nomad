job "librespeed" {
  datacenters = ["lab"]
  type        = "service"

  constraint {
    attribute = meta.network_node
    value     = "true"
  }

  group "speedtest" {
    count = 1

    network {
      mode = "bridge"

      port "librespeed" {
        to           = 80
        static       = 8080
        host_network = "default"
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    task "librespeed" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/librespeed:latest"
        ports = ["librespeed"]
      }

      service {
        name = "librespeed"
        port = "librespeed"

        check {
          name     = "librespeed"
          type     = "http"
          port     = "librespeed"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}

