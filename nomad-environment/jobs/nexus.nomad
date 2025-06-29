job "nexus-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "nexus" {
    count = 1

    network {
      port "nexus" {
        static = 8081
      }
    }

    volume "nexus-data" {
      type      = "host"
      read_only = false
      source    = "nexus-data"
    }

    task "nexus" {
      driver = "docker"

      config {
        image = "sonatype/nexus3:latest"
        ports = ["nexus"]
        
        volumes = [
          "nexus-data:/nexus-data"
        ]
      }

      env {
        NEXUS_SECURITY_RANDOMPASSWORD = "false"
      }

      resources {
        cpu    = 1000
        memory = 2048
      }

      service {
        name = "nexus"
        port = "nexus"

        check {
          type     = "http"
          path     = "/"
          interval = "30s"
          timeout  = "10s"
        }
      }
    }
  }
}
