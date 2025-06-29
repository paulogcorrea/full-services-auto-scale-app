job "node-exporter" {
  datacenters = ["dc1"]
  type        = "system"

  group "node-exporter" {
    count = 1

    network {
      port "metrics" {
        static = 9100
      }
    }

    task "node-exporter" {
      driver = "docker"

      config {
        image = "prom/node-exporter:latest"
        ports = ["metrics"]
        
        args = [
          "--path.procfs=/host/proc",
          "--path.sysfs=/host/sys",
          "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)"
        ]
        
        volumes = [
          "/proc:/host/proc:ro",
          "/sys:/host/sys:ro",
          "/:/rootfs:ro"
        ]
        
        privileged = true
      }

      resources {
        cpu    = 100
        memory = 128
      }

      service {
        name = "node-exporter"
        port = "metrics"

        check {
          type     = "http"
          path     = "/metrics"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
