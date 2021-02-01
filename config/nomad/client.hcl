region="global"
datacenter = "lab"
data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"
log_level = "INFO"

client {
  enabled = true
  servers = ["nomad.service.consul:4647"]

  options = {
    "driver.denylist" = "docker,java,exec,raw_exec,qemu"
  }

  meta = {
    storage = "ssd"
    media_node = "true"
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

