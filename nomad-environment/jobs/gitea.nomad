job "gitea" {
  datacenters = ["dc1"]
  type        = "service"

  group "gitea" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    network {
      port "http" {
        static = 3000
      }
      port "ssh" {
        static = 2222
      }
    }

    volume "gitea-data" {
      type      = "host"
      read_only = false
      source    = "gitea_data"
    }

    task "gitea" {
      driver = "docker"

      config {
        image = "gitea/gitea:latest"
        ports = ["http", "ssh"]
        
        mount {
          type   = "volume"
          target = "/data"
          source = "gitea-data"
        }
      }

      env {
        USER  = "git"
        ROOT_URL = "http://localhost:3000/"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "gitea"
        port = "http"
      }

      service {
        name = "gitea-ssh"
        port = "ssh"
      }
    }
  }
}

