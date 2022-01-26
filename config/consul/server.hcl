datacenter = "lab"
data_dir = "/var/lib/consul"
client_addr = "127.0.0.1 {{GetPrivateIP}}"
bind_addr = "{{GetPrivateIP}}"

ui = true
server = true
bootstrap_expect=1

ports {
  grpc = 8502
}

connect {
  enabled = true
}

