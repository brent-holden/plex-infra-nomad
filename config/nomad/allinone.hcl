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

  options = {
    "driver.denylist" = "docker,java"
  }

  host_network "default" {
    cidr = "192.168.0.0/23"
  }
}

plugin_dir = "/opt/nomad/plugins"

plugin "containerd-driver" {
  config {
    enabled = true
    containerd_runtime = "io.containerd.runc.v2"
    stats_interval = "5s"
  }
}
