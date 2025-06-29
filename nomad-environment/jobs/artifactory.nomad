job "artifactory-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "artifactory" {
    count = 1

    network {
      port "artifactory" {
        static = 8082
      }
    }

    volume "artifactory-data" {
      type      = "host"
      read_only = false
      source    = "artifactory-data"
    }

    task "artifactory" {
      driver = "docker"

      config {
        image = "releases-docker.jfrog.io/jfrog/artifactory-oss:latest"
        ports = ["artifactory"]
        
        volumes = [
          "artifactory-data:/var/opt/jfrog/artifactory"
        ]
      }

      env {
        JF_SHARED_DATABASE_TYPE = "derby"
      }

      resources {
        cpu    = 1000
        memory = 2048
      }

      service {
        name = "artifactory"
        port = "artifactory"

        check {
          type     = "http"
          path     = "/artifactory/webapp/#/login"
          interval = "30s"
          timeout  = "10s"
        }
      }
    }
  }
}
