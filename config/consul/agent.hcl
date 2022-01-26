datacenter = "lab"
data_dir = "/opt/consul"
bind_addr = "{{GetPrivateIP}}"
ui = true

retry_join = ["consul.service.consul:8301"]

ports {
  grpc = 8502
}

connect {
  enabled = true
}

