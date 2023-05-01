client {

  host_volume "flame-config" {
    path = "/opt/services/flame"
    read_only = false
  }

  host_volume "rclone-cache-backup" {
    path = "/mnt/rclone/cache/backup"
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
