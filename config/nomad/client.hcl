region="global"
datacenter = "lab"
data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"
log_level = "INFO"

client {
  enabled = true
  servers = ["nomad.service.consul:4647"]

  meta = {
    storage = "ssd"
    media_node = "true"
    network_node = "true"
  }
}

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}

