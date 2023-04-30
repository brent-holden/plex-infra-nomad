job "metrics" {
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"

  constraint {
    attribute = "${meta.network_node}"
    value     = "true"
  }

  group "grafana" {
    count = 1

    network {
      mode = "bridge"

      port "grafana" {
        static = 3001
        to     = 3000
      }
    }

    service {
      name = "grafana"
      port = "3000"
      tags = ["metrics"]

      check {
        name     = "grafana"
        type     = "http"
        port     = "grafana"
        path     = "/api/health"
        interval = "30s"
        timeout  = "2s"
        header {
          Accept = ["application/json"]
        }
      }

    }

    volume "config" {
      type      = "host"
      read_only = false
      source    = "grafana-config"
    }

    task "dashboard" {
      driver = "docker"

      volume_mount {
        volume      = "config"
        destination = "/var/lib/grafana"
        read_only   = false
      }

      config {
        image = "docker.io/grafana/grafana:latest"
      }
    }
  }

  group "prometheus" {
    count = 1

    network {
      mode = "bridge"

      port "prometheus_ui" {
        static = 9090
        to     = 9090
      }
    }

    service {
      name = "prometheus"
      port = "prometheus_ui"
      tags = ["metrics"]

      check {
        name            = "prometheus"
        type            = "http"
        path            = "/-/healthy"
        tls_skip_verify = true
        interval        = "10s"
        timeout         = "2s"
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    task "prometheus" {
      driver = "docker"

      env {
        GF_PATHS_DATA         = "/var/lib/grafana"
        GF_AUTH_BASIC_ENABLED = "false"
        GF_INSTALL_PLUGINS    = "grafana-piechart-panel"
      }

      config {
        image = "prom/prometheus:latest"
        ports = ["prometheus_ui"]

        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
        ]
      }

      template {
        change_mode = "restart"
        data        = "{{ key \"prometheus/config/prometheus.yml\" }}"
        destination = "local/prometheus.yml"
      }
    }
  }
}

