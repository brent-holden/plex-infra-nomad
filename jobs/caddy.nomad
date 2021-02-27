job "caddy" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  update {
    max_parallel      = 1
    min_healthy_time  = "30s"
    healthy_deadline  = "1m"
    progress_deadline = "3m"
    auto_revert       = true
    canary            = 0
  }

  group "caddy" {
    count = 1
    network {
      port "http"   { static  = 80 }
      port "https"  { static  = 443 }
    }

    service {
      name = "caddy"
      tags = ["https","request"]
      port = "https"

      check {
        type     = "tcp"
        port     = "https"
        interval = "60s"
        timeout  = "5s"
      }
    }

    task "caddy" {
      driver = "containerd-driver"

      config {
        image         = "docker.io/library/caddy:${RELEASE}"
        command       = "caddy"
        args          = [
                          "run",
                          "-config",
                          "/local/Caddyfile"
                        ]

        host_network  = true
        cap_add       = ["CAP_NET_BIND_SERVICE"]

        mounts  = [
                    {
                      type    = "bind"
                      source  = "/opt/caddy/config"
                      target  = "/config"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      source  = "/opt/caddy/data"
                      target  = "/data"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/downloads"
                      source  = "/mnt/downloads/complete"
                      options = ["rbind", "ro"]
                    }
                  ]
      }

      template {
        data          = "IMAGE_ID={{ keyOrDefault \"caddy/config/image_id\" \"1\" }}\nRELEASE={{ keyOrDefault \"caddy/config/release\" \"latest\" }}"
        destination   = "env_info"
        env           = true
      }

      template {
        data        = <<EOH
{{ key "/caddy/config/external_hostname" }}

reverse_proxy /*          ombi.service.consul:3579

redir         /sonarr     /sonarr/
reverse_proxy /sonarr/*   sonarr.service.consul:8989

redir         /radarr     /radarr/
reverse_proxy /radarr/*   radarr.service.consul:7878

redir         /lidarr     /lidarr/
reverse_proxy /lidarr/*   lidarr.service.consul:8686

redir         /sabnzbd    /sabnzbd/
reverse_proxy /sabnzbd/*  sabnzbd.service.consul:8080

redir         /hydra2     /hydra2/
reverse_proxy /hydra2/*   hydra2.service.consul:5076

redir         /tautulli   /tautulli/
reverse_proxy /tautulli*  tautulli.service.consul:8181

handle_path   /downloads* {
  root  * /downloads
  file_server browse
  basicauth {
    {{ range tree "caddy/config/basicauth_users/" -}}
      {{- .Key }} {{ .Value }}
    {{ end -}}
  }
}
EOH
        destination = "local/Caddyfile"
        change_mode = "restart"
      }

      resources {
        cpu    = 200
        memory = 512 
      }

      kill_timeout = "20s"
    }
  }
}
