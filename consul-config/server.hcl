datacenter = "lab"
data_dir = "/var/lib/consul"
client_addr = "{{GetPrivateIP}}"
bind_addr = "{{GetPrivateIP}}"

ui = true
server = true
bootstrap_expect=1

encrypt = "xjUnRl7uoiHjFtDgaXDXFwUpayQtzKdSDZnYwTAF+Ag="

connect {
  enabled = true
}

