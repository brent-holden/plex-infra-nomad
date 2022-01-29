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
  servers = ["127.0.0.1:4647"]

  host_network "default" {
    cidr = "192.168.0.0/23"
  }
}

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}
