client {

  host_volume "media-base" {
    path = "/mnt/rclone/drive/media"
    read_only = true
  }

  host_volume "plex-config" {
    path = "/opt/services/plex"
    read_only = false
  }

  host_volume "plex-transcoder" {
    path = "/mnt/transcode"
    read_only = false
  }

  host_volume "tautulli-config" {
    path = "/opt/services/tautulli"
    read_only = false
  }

}
