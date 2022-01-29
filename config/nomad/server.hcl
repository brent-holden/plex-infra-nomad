region = "global"
datacenter = "lab"
data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"

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
    media_node = "true"
  }
}

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}

