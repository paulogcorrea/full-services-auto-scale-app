job "cadvisor" {
  datacenters = ["dc1"]
  type        = "system"

  group "cadvisor" {
    count = 1

    network {
      port "http" {
        static = 8083
      }
    }

    task "cadvisor" {
      driver = "docker"

      config {
        image = "gcr.io/cadvisor/cadvisor:latest"
        ports = ["http"]
        
        volumes = [
          "/:/rootfs:ro",
          "/var/run:/var/run:ro",
          "/sys:/sys:ro",
          "/var/lib/docker/:/var/lib/docker:ro",
          "/dev/disk/:/dev/disk:ro"
        ]
        
        privileged = true
        
        devices = [
          {
            host_path = "/dev/kmsg"
            container_path = "/dev/kmsg"
          }
        ]
      }

      resources {
        cpu    = 300
        memory = 200
      }

      service {
        name = "cadvisor"
        port = "http"

        check {
          type     = "http"
          path     = "/healthz"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
