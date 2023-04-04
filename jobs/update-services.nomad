job "update-services" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "batch"

  periodic {
    cron             = "5 5 * * * *"
    time_zone        = "America/New_York"
    prohibit_overlap = true
  }

  group "update-services" {
    count = 1

    task "update" {
      driver = "docker"

      env {
        CONSUL_HTTP_ADDR = "[[ .common.env.consul_http_addr ]]"
      }

      config {
        image = "docker.io/bholden/update-services:latest"
        volumes = [
          "local/levant.yml:/app/levant.yml"
        ]
      }

      template {
        data        = "{{ key \"update-services/config/levant.yml\" }}"
        destination = "local/levant.yml"
      }
    }
  }
}
