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
        image = "docker.bintray.io/jfrog/artifactory-oss:6.23.41"
        ports = ["artifactory"]
        
        volumes = [
          "artifactory-data:/var/opt/jfrog/artifactory"
        ]
      }

      env {
        # Simplified configuration for version 6.x
        DB_TYPE = "derby"
      }

      restart {
        attempts = 5
        interval = "10m"
        delay    = "30s"
        mode     = "fail"
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
          path     = "/artifactory/api/system/ping"
          interval = "60s"
          timeout  = "15s"
          initial_status = "passing"
          success_before_passing = 2
          failures_before_critical = 5
          check_restart {
            limit = 5
            grace = "90s"
            ignore_warnings = true
          }
        }
      }
    }
  }
}
