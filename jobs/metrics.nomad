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
        static = 3000
        to     = 3000
      }
    }

    service {
      name = "grafana"
      port = "3000"
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
      tags = ["urlprefix-/"]
      port = "prometheus_ui"

      check {
        name     = "prometheus_ui port alive"
        type     = "http"
        path     = "/-/healthy"
        interval = "10s"
        timeout  = "2s"
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
        change_mode = "noop"
        destination = "local/prometheus.yml"

        data = <<-EOH
          ---
          global:
            scrape_interval:     5s
            evaluation_interval: 5s

          scrape_configs:
            - job_name: 'traefik_metrics'
              static_configs:
              - targets: ['traefik.service.consul:8082']

            - job_name: 'nomad_metrics'
              consul_sd_configs:
              - server: 'consul.service.consul:8500'
                services: ['nomad-client', 'nomad']
              re[[ .nomad.datacenter ]]el_configs:
              - source_[[ .nomad.datacenter ]]els: ['__meta_consul_tags']
                regex: '(.*)http(.*)'
                action: keep
              scrape_interval: 5s
              metrics_path: /v1/metrics
              params:
                format: ['prometheus']

            - job_name: 'consul_metrics'
              metrics_path: /metrics
              consul_sd_configs:
                - server: 'consul.service.consul:8500'
              re[[ .nomad.datacenter ]]el_configs:
              - source_[[ .nomad.datacenter ]]els: [__meta_consul_service]
                regex: (.+)-sidecar-proxy
                action: drop
              - source_[[ .nomad.datacenter ]]els: [__meta_consul_service]
                regex: (.+)
                target_[[ .nomad.datacenter ]]el: service
              - source_[[ .nomad.datacenter ]]els: [__meta_consul_service_metadata_metrics_port_envoy]
                regex: (.+)
                action: keep
              - source_[[ .nomad.datacenter ]]els: [__address__,__meta_consul_service_metadata_metrics_port_envoy]
                regex: (.+)(?::\d+);(\d+)
                action: replace
                replacement: $1:$2
                target_[[ .nomad.datacenter ]]el: __address__
              scrape_interval: 5s
          EOH
      }
    }
  }
}

