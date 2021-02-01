job "hydra2" {
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

  group "hydra2" {
    count = 1
    network {
      port "hydra2" { static = 5076 }
    }

    service {
      name = "hydra2"
      tags = ["http","index"]
      port = "hydra2"

      check {
        type     = "tcp"
        port     = "hydra2"
        interval = "120s"
        timeout  = "60s"
      }
    }

    ephemeral_disk {
      sticky  = true
      size    = 2048
    }

    task "hydra2" {
      driver = "podman"

      env {
       PGID = "1100"
       PUID = "1100"
      }

      config {
        image         = "docker://docker.io/linuxserver/nzbhydra2:${RELEASE}"
        network_mode  = "bridge"
        ports         = ["hydra2"]
        volumes       = ["/opt/hydra2:/config","/mnt/downloads:/downloads"]
      }

      template {
        data          = "IMAGE_ID={{ key \"hydra2/config/image_id\" }}\nIMAGE={{ key \"hydra2/config/image\" }}\nRELEASE={{ key \"hydra2/config/release\" }}\nNOMAD_JOB_NAME={{ env \"NOMAD_JOB_NAME\" }}\n"
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 300
        memory = 512
      }

      kill_timeout = "20s"
    }
  }
}
