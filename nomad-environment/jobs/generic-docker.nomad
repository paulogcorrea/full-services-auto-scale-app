job "generic-docker" {
  datacenters = ["dc1"]
  type        = "service"

  group "app" {
    count = 1

    network {
      port "http" {
        static = 8099
      }
    }

    task "generic-app" {
      driver = "docker"

      env {
        # Environment variables that can be set from outside
        DOCKER_IMAGE = "${DOCKER_IMAGE}"
        APP_PORT = "${APP_PORT}"
        APP_NAME = "${APP_NAME}"
        CONTAINER_COMMAND = "${CONTAINER_COMMAND}"
        CONTAINER_ARGS = "${CONTAINER_ARGS}"
        # Additional environment variables
        ENV_VAR_1 = "${ENV_VAR_1}"
        ENV_VAR_2 = "${ENV_VAR_2}"
        ENV_VAR_3 = "${ENV_VAR_3}"
        ENV_VAR_4 = "${ENV_VAR_4}"
        ENV_VAR_5 = "${ENV_VAR_5}"
      }

      config {
        image = "${DOCKER_IMAGE}"
        ports = ["http"]
        
        # Optional command override
        command = "${CONTAINER_COMMAND}"
        args = "${CONTAINER_ARGS}"
        
        # Common Docker options
        network_mode = "bridge"
        
        # Volume mounts for data persistence
        volumes = [
          "generic-app-data:/app/data",
          "generic-app-logs:/app/logs",
          "generic-app-config:/app/config"
        ]
        
        # Port mapping from container to host
        port_map {
          http = "${APP_PORT}"
        }
      }

      # Resource allocation
      resources {
        cpu    = 1000  # 1 CPU core
        memory = 1024  # 1GB RAM
      }

      # Service registration for Consul
      service {
        name = "generic-docker"
        port = "http"
        tags = [
          "generic",
          "docker",
          "user-app",
          "${APP_NAME}"
        ]

        # Health check - flexible for different types of apps
        check {
          type     = "tcp"
          interval = "30s"
          timeout  = "5s"
        }

        # HTTP health check (optional, will fail gracefully if not applicable)
        check {
          name     = "http-health"
          type     = "http"
          path     = "/"
          interval = "30s"
          timeout  = "5s"
          check_restart {
            limit = 3
            grace = "10s"
          }
        }

        # Traefik labels for automatic service discovery
        meta {
          traefik.enable = "true"
          traefik.http.routers.generic-docker.rule = "Host(`generic.localhost`)"
          traefik.http.routers.generic-docker.entrypoints = "web"
          traefik.http.services.generic-docker.loadbalancer.server.port = "8099"
          
          # HTTPS routing
          traefik.http.routers.generic-docker-secure.rule = "Host(`generic.localhost`)"
          traefik.http.routers.generic-docker-secure.entrypoints = "websecure"
          traefik.http.routers.generic-docker-secure.tls = "true"
        }
      }

      # Logs configuration
      logs {
        max_files     = 5
        max_file_size = 15
      }

      # Kill timeout
      kill_timeout = "20s"

      # Restart policy
      restart {
        attempts = 3
        interval = "30m"
        delay    = "15s"
        mode     = "fail"
      }
    }

    # Restart policy for the group
    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    # Update strategy
    update {
      max_parallel      = 1
      min_healthy_time  = "10s"
      healthy_deadline  = "3m"
      progress_deadline = "10m"
      auto_revert       = false
      canary            = 0
    }
  }
}
