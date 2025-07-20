job "drone-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "drone" {
    count = 1

    # Configure networking
    network {
      port "http" {
        static = 8080
        to     = 80
      }
      port "grpc" {
        static = 9000
        to     = 9000
      }
    }

    # Configure persistent storage
    volume "drone_data" {
      type            = "host"
      source          = "drone_data"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "drone-server" {
      driver = "docker"

      # Mount the volume
      volume_mount {
        volume      = "drone_data"
        destination = "/data"
      }

      config {
        image = "drone/drone:2"
        ports = ["http", "grpc"]

        # Set container environment
        environment = {
          # Core Drone configuration
          DRONE_DATABASE_DRIVER    = "sqlite3"
          DRONE_DATABASE_DATASOURCE = "/data/database.sqlite"
          DRONE_RPC_SECRET         = "${DRONE_RPC_SECRET}"
          DRONE_SERVER_HOST        = "${DRONE_SERVER_HOST}"
          DRONE_SERVER_PROTO       = "http"

          # GitHub integration (configurable)
          DRONE_GITHUB_CLIENT_ID     = "${DRONE_GITHUB_CLIENT_ID}"
          DRONE_GITHUB_CLIENT_SECRET = "${DRONE_GITHUB_CLIENT_SECRET}"

          # GitLab integration (configurable)
          DRONE_GITLAB_SERVER        = "${DRONE_GITLAB_SERVER}"
          DRONE_GITLAB_CLIENT_ID     = "${DRONE_GITLAB_CLIENT_ID}"
          DRONE_GITLAB_CLIENT_SECRET = "${DRONE_GITLAB_CLIENT_SECRET}"

          # Gitea integration (configurable)
          DRONE_GITEA_SERVER         = "${DRONE_GITEA_SERVER}"
          DRONE_GITEA_CLIENT_ID      = "${DRONE_GITEA_CLIENT_ID}"
          DRONE_GITEA_CLIENT_SECRET  = "${DRONE_GITEA_CLIENT_SECRET}"

          # Admin user configuration
          DRONE_USER_CREATE = "${DRONE_USER_CREATE}"

          # Logs and debugging
          DRONE_LOGS_DEBUG = "true"
          DRONE_LOGS_TRACE = "false"

          # Security
          DRONE_TLS_AUTOCERT = "false"
          DRONE_REGISTRATION_CLOSED = "false"

          # Repository settings
          DRONE_REPOSITORY_FILTER = ""
          DRONE_CLEANUP_INTERVAL = "1h"
          DRONE_CLEANUP_DISABLED = "false"
        }
      }

      # Resource allocation
      resources {
        cpu    = 1000   # 1 CPU core
        memory = 2048   # 2GB RAM
      }

      # Health check
      service {
        name = "drone"
        port = "http"
        tags = [
          "drone",
          "ci-cd",
          "continuous-integration",
          "automation"
        ]

        check {
          type     = "http"
          path     = "/healthz"
          interval = "30s"
          timeout  = "5s"

          check_restart {
            limit           = 3
            grace           = "10s"
            ignore_warnings = false
          }
        }

        # Traefik integration
        meta {
          traefik-enable                 = "true"
          traefik-http-routers-drone-rule = "Host(`drone.localhost`)"
          traefik-http-services-drone-loadbalancer-server-port = "80"
        }
      }

      # Restart policy
      restart {
        attempts = 3
        delay    = "30s"
        interval = "2m"
        mode     = "fail"
      }

      # Template for environment variables with defaults
      template {
        data = <<EOF
# Drone Configuration Template
{{ with secret "secret/drone" }}
DRONE_RPC_SECRET="{{ .Data.rpc_secret | default "supersecret" }}"
DRONE_SERVER_HOST="{{ .Data.server_host | default "localhost:8080" }}"

# GitHub OAuth App (optional)
DRONE_GITHUB_CLIENT_ID="{{ .Data.github_client_id | default "" }}"
DRONE_GITHUB_CLIENT_SECRET="{{ .Data.github_client_secret | default "" }}"

# GitLab OAuth App (optional)  
DRONE_GITLAB_SERVER="{{ .Data.gitlab_server | default "http://localhost:8090" }}"
DRONE_GITLAB_CLIENT_ID="{{ .Data.gitlab_client_id | default "" }}"
DRONE_GITLAB_CLIENT_SECRET="{{ .Data.gitlab_client_secret | default "" }}"

# Gitea OAuth App (optional)
DRONE_GITEA_SERVER="{{ .Data.gitea_server | default "http://localhost:3000" }}"
DRONE_GITEA_CLIENT_ID="{{ .Data.gitea_client_id | default "" }}"
DRONE_GITEA_CLIENT_SECRET="{{ .Data.gitea_client_secret | default "" }}"

# Admin user (username:admin,machine:false,admin:true,token:TOKEN)
DRONE_USER_CREATE="{{ .Data.admin_user | default "username:admin,machine:false,admin:true" }}"
{{ else }}
# Default configuration (Vault not available)
DRONE_RPC_SECRET="supersecret"
DRONE_SERVER_HOST="localhost:8080"
DRONE_GITHUB_CLIENT_ID=""
DRONE_GITHUB_CLIENT_SECRET=""
DRONE_GITLAB_SERVER="http://localhost:8090"
DRONE_GITLAB_CLIENT_ID=""
DRONE_GITLAB_CLIENT_SECRET=""
DRONE_GITEA_SERVER="http://localhost:3000"
DRONE_GITEA_CLIENT_ID=""
DRONE_GITEA_CLIENT_SECRET=""
DRONE_USER_CREATE="username:admin,machine:false,admin:true"
{{ end }}
EOF
        destination = "local/drone.env"
        env         = true
      }

      # Logs configuration
      logs {
        max_files     = 3
        max_file_size = 50
      }
    }
  }
}
