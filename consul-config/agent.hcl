datacenter = "lab"
data_dir = "/opt/consul"
bind_addr = "{{GetPrivateIP}}"
ui = true

encrypt = "xjUnRl7uoiHjFtDgaXDXFwUpayQtzKdSDZnYwTAF+Ag="
retry_join = ["consul.service.consul:8301"]

connect {
  enabled = true
}

