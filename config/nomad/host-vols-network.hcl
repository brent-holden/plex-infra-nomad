client {

  host_volume "rclone-cache-backup" {
    path = "/mnt/rclone/cache/backup"
    read_only = false
  }
  
  host_volume "netbootxyz-config" {
    path = "/opt/services/netbootxyz/config"
    read_only = false
  }
  
  host_volume "netbootxyz-assets" {
    path = "/opt/services/netbootxyz/assets"
    read_only = false
  }
  
  host_volume "grafana-config" {
    path = "/opt/services/grafana"
    read_only = false
  }

  host_volume "authelia-config" {
    path = "/opt/services/authelia"
    read_only = false
  }

  host_volume "traefik-certs" {
    path = "/opt/services/traefik"
    read_only = false
  }

}

