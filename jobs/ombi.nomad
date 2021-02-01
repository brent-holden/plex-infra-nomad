job "ombi" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  update {
    max_parallel      = 1
    min_healthy_time  = "5s"
    healthy_deadline  = "2m"
    progress_deadline = "3m"
    auto_revert       = true
    canary            = 0
  }

  group "ombi" {
    count = 1
    network {
      port "ombi" { static = 3579 }
    }

    service {
      name = "ombi"
      tags = ["http","request"]
      port = "ombi"

      check {
        type     = "tcp"
        port     = "ombi"
        interval = "30s"
        timeout  = "2s"
      }
    }

    ephemeral_disk {
      sticky  = true
      size    = 2048
    }

    task "ombi" {
      driver = "podman"

      env {
       PGID = "1100"
       PUID = "1100"
       TZ   = "America/New_York"
      }

      config {
        image         = "docker://docker.io/linuxserver/ombi:${RELEASE}"
        network_mode  = "bridge"
        ports         = ["ombi"]
        volumes       = ["/opt/ombi:/config"]
      }

      template {
        data          = "IMAGE_ID={{ key \"ombi/config/image_id\" }}\nIMAGE={{ key \"ombi/config/image\" }}\nRELEASE={{ key \"ombi/config/release\" }}\nNOMAD_JOB_NAME={{ env \"NOMAD_JOB_NAME\" }}\n"
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 100
        memory = 2048
      }

      kill_timeout = "20s"
    }
  }
}
