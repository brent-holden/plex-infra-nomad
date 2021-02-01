datacenter = "lab"
data_dir = "/opt/consul"
bind_addr = "{{GetPrivateIP}}"
ui = true

retry_join = ["consul.service.consul:8301"]

connect {
  enabled = true
}

