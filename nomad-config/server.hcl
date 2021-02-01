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

  options = {
    "driver.denylist" = "docker,java,exec,raw_exec,qemu"
  }

  host_network "lan" {
    cidr = "192.168.0.0/23"
  }

  host_network "lab" {
    cidr = "192.168.10.0/24"
  }

  meta = {
    storage = "hdd"
    network_node = "true"
  }
}

plugin_dir = "/opt/nomad/plugins"

plugin "nomad-driver-podman" {
  config {
    volumes {
      enabled      = true
      selinuxlabel = "z"
    }
  }
}

