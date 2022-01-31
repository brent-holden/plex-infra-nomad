region="global"
datacenter = "lab"
data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"
log_level = "INFO"

telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}

client {
  enabled = true
  servers = ["nomad.service.consul:4647"]

  meta = {
    storage = "ssd"
    media_node = "true"
    network_node = "true"
  }

  host_volume "downloads" {
    path = "/mnt/downloads"
    read_only = false
  }

  host_volume "downloads-complete" {
    path = "/mnt/downloads/complete"
    read_only = true
  }

  host_volume "media-base" {
    path = "/mnt/rclone/media"
    read_only = true
  }

  host_volume "media-books" {
    path = "/mnt/rclone/media/Books"
    read_only = false
  }

  host_volume "media-movies" {
    path = "/mnt/rclone/media/Movies"
    read_only = false
  }

  host_volume "media-music" {
    path = "/mnt/rclone/media/Music"
    read_only = false
  }

  host_volume "media-tv" {
    path = "/mnt/rclone/media/TV"
    read_only = false
  }

  host_volume "kavita-config" {
    path = "/opt/kavita"
    read_only = false
  }

  host_volume "lidarr-config" {
    path = "/opt/lidarr"
    read_only = false
  }

  host_volume "ombi-config" {
    path = "/opt/ombi"
    read_only = false
  }

  host_volume "plex-config" {
    path = "/opt/plex"
    read_only = false
  }

  host_volume "plex-transcoder" {
    path = "/mnt/transcode"
    read_only = false
  }

  host_volume "prowlarr-config" {
    path = "/opt/prowlarr"
    read_only = false
  }

  host_volume "radarr-config" {
    path = "/opt/radarr"
    read_only = false
  }

  host_volume "readarr-config" {
    path = "/opt/readarr"
    read_only = false
  }

  host_volume "sabnzbd-config" {
    path = "/opt/sabnzbd"
    read_only = false
  }

  host_volume "sonarr-config" {
    path = "/opt/sonarr"
    read_only = false
  }

  host_volume "tautulli-config" {
    path = "/opt/tautulli"
    read_only = false
  }

}

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}

