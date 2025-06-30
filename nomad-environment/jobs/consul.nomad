job "consul-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "consul" {
    count = 1

    network {
      port "http" {
        static = 8500
      }
      port "dns" {
        static = 8600
      }
      port "server" {
        static = 8300
      }
      port "grpc" {
        static = 8502
      }
    }

    volume "consul-data" {
      type      = "host"
      read_only = false
      source    = "consul-data"
    }

    task "consul" {
      driver = "docker"

      config {
        image = "consul:latest"
        ports = ["http", "dns", "server", "grpc"]
        
        args = [
          "agent",
          "-dev",
          "-client=0.0.0.0",
          "-bind=0.0.0.0",
          "-ui",
          "-bootstrap-expect=1",
          "-data-dir=/consul/data"
        ]
        
        volumes = [
          "consul-data:/consul/data"
        ]
      }

      env {
        CONSUL_LOCAL_CONFIG = jsonencode({
          datacenter = "dc1"
          server     = true
          ui_config = {
            enabled = true
          }
          connect = {
            enabled = true
          }
          log_level = "INFO"
        })
      }

      resources {
        cpu    = 256
        memory = 512
      }
    }
  }
}
