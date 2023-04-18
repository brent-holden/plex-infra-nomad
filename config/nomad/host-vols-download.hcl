client {

  host_volume "downloads" {
    path = "/mnt/downloads"
    read_only = false
  }

  host_volume "downloads-complete" {
    path = "/mnt/downloads/complete"
    read_only = true
  }

  host_volume "media-base" {
    path = "/mnt/rclone/drive/media"
    read_only = true
  }

  host_volume "media-books" {
    path = "/mnt/rclone/drive/media/Books"
    read_only = false
  }

  host_volume "media-movies" {
    path = "/mnt/rclone/drive/media/Movies"
    read_only = false
  }

  host_volume "media-music" {
    path = "/mnt/rclone/drive/media/Music"
    read_only = false
  }

  host_volume "media-tv" {
    path = "/mnt/rclone/drive/media/TV"
    read_only = false
  }

  host_volume "overseerr-config" {
    path = "/opt/services/overseerr"
    read_only = false
  }

  host_volume "readarr-config" {
    path = "/opt/services/readarr"
    read_only = false
  }

  host_volume "radarr-config" {
    path = "/opt/services/radarr"
    read_only = false
  }

  host_volume "sonarr-config" {
    path = "/opt/services/sonarr"
    read_only = false
  }

  host_volume "lidarr-config" {
    path = "/opt/services/lidarr"
    read_only = false
  }

  host_volume "prowlarr-config" {
    path = "/opt/services/prowlarr"
    read_only = false
  }

  host_volume "kavita-config" {
    path = "/opt/services/kavita"
    read_only = false
  }

  host_volume "sabnzbd-config" {
    path = "/opt/services/sabnzbd"
    read_only = false
  }
}
