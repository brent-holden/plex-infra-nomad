region = "global"
datacenter = "lab"
data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"

consul {
  address = "consul.service.consul:8500"
}

telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}

server {
  enabled = true
  bootstrap_expect = 1
}

client {
  enabled = true
  servers = ["nomad.service.consul:4647"]

  host_network "default" {
    cidr = "192.168.0.0/23"
  }

  host_network "lab" {
    cidr = "192.168.10.0/24"
  }

  meta = {
    storage = "hdd"
    network_node = "true"
  }

  host_volume "netbootxyz-config" {
    path = "/opt/netbootxyz/config"
    read_only = false
  }

  host_volume "netbootxyz-assets" {
    path = "/opt/netbootxyz/assets"
    read_only = false
  }

  host_volume "grafana-config" {
    path = "/opt/grafana"
    read_only = false
  }
}

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}

