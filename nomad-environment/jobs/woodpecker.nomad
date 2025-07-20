job "woodpecker-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "woodpecker" {
    count = 1

    # Configure networking
    network {
      port "http" {
        static = 8000
        to     = 8000
      }
      port "grpc" {
        static = 9000
        to     = 9000
      }
    }

    # Configure persistent storage
    volume "woodpecker_data" {
      type            = "host"
      source          = "woodpecker_data"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "woodpecker-server" {
      driver = "docker"

      # Mount the volume
      volume_mount {
        volume      = "woodpecker_data"
        destination = "/var/lib/woodpecker"
      }

      config {
        image = "woodpeckerci/woodpecker-server:latest"
        ports = ["http", "grpc"]

        # Set container environment
        environment = {
          # Core Woodpecker configuration
          WOODPECKER_HOST                = "${WOODPECKER_HOST}"
          WOODPECKER_AGENT_SECRET        = "${WOODPECKER_AGENT_SECRET}"
          WOODPECKER_DATABASE_DRIVER     = "sqlite3"
          WOODPECKER_DATABASE_DATASOURCE = "/var/lib/woodpecker/woodpecker.sqlite"

          # GitHub integration (configurable)
          WOODPECKER_GITHUB                = "${WOODPECKER_GITHUB}"
          WOODPECKER_GITHUB_CLIENT         = "${WOODPECKER_GITHUB_CLIENT}"
          WOODPECKER_GITHUB_SECRET         = "${WOODPECKER_GITHUB_SECRET}"

          # GitLab integration (configurable)
          WOODPECKER_GITLAB                = "${WOODPECKER_GITLAB}"
          WOODPECKER_GITLAB_URL            = "${WOODPECKER_GITLAB_URL}"
          WOODPECKER_GITLAB_CLIENT         = "${WOODPECKER_GITLAB_CLIENT}"
          WOODPECKER_GITLAB_SECRET         = "${WOODPECKER_GITLAB_SECRET}"

          # Gitea integration (configurable)
          WOODPECKER_GITEA                 = "${WOODPECKER_GITEA}"
          WOODPECKER_GITEA_URL             = "${WOODPECKER_GITEA_URL}"
          WOODPECKER_GITEA_CLIENT          = "${WOODPECKER_GITEA_CLIENT}"
          WOODPECKER_GITEA_SECRET          = "${WOODPECKER_GITEA_SECRET}"

          # Admin user configuration
          WOODPECKER_ADMIN                 = "${WOODPECKER_ADMIN}"

          # Logs and debugging
          WOODPECKER_LOG_LEVEL             = "info"

          # Security
          WOODPECKER_OPEN                  = "${WOODPECKER_OPEN}"
          WOODPECKER_ORGS                  = "${WOODPECKER_ORGS}"

          # gRPC settings
          WOODPECKER_GRPC_ADDR             = ":9000"
        }
      }

      # Resource allocation
      resources {
        cpu    = 1000   # 1 CPU core
        memory = 1024   # 1GB RAM
      }

      # Health check
      service {
        name = "woodpecker"
        port = "http"
        tags = [
          "woodpecker",
          "ci-cd",
          "continuous-integration",
          "automation",
          "pipeline"
        ]

        check {
          type     = "http"
          path     = "/api/healthz"
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
          traefik-http-routers-woodpecker-rule = "Host(`woodpecker.localhost`)"
          traefik-http-services-woodpecker-loadbalancer-server-port = "8000"
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
# Woodpecker Configuration Template
{{ with secret "secret/woodpecker" }}
WOODPECKER_HOST="{{ .Data.host | default "http://localhost:8000" }}"
WOODPECKER_AGENT_SECRET="{{ .Data.agent_secret | default "supersecret" }}"

# GitHub OAuth App (optional)
WOODPECKER_GITHUB="{{ .Data.github_enabled | default "false" }}"
WOODPECKER_GITHUB_CLIENT="{{ .Data.github_client | default "" }}"
WOODPECKER_GITHUB_SECRET="{{ .Data.github_secret | default "" }}"

# GitLab OAuth App (optional)  
WOODPECKER_GITLAB="{{ .Data.gitlab_enabled | default "false" }}"
WOODPECKER_GITLAB_URL="{{ .Data.gitlab_url | default "http://localhost:8090" }}"
WOODPECKER_GITLAB_CLIENT="{{ .Data.gitlab_client | default "" }}"
WOODPECKER_GITLAB_SECRET="{{ .Data.gitlab_secret | default "" }}"

# Gitea OAuth App (optional)
WOODPECKER_GITEA="{{ .Data.gitea_enabled | default "false" }}"
WOODPECKER_GITEA_URL="{{ .Data.gitea_url | default "http://localhost:3000" }}"
WOODPECKER_GITEA_CLIENT="{{ .Data.gitea_client | default "" }}"
WOODPECKER_GITEA_SECRET="{{ .Data.gitea_secret | default "" }}"

# Admin users (comma-separated list of usernames)
WOODPECKER_ADMIN="{{ .Data.admin_users | default "admin" }}"

# Registration settings
WOODPECKER_OPEN="{{ .Data.open_registration | default "false" }}"
WOODPECKER_ORGS="{{ .Data.allowed_orgs | default "" }}"
{{ else }}
# Default configuration (Vault not available)
WOODPECKER_HOST="http://localhost:8000"
WOODPECKER_AGENT_SECRET="supersecret"
WOODPECKER_GITHUB="false"
WOODPECKER_GITHUB_CLIENT=""
WOODPECKER_GITHUB_SECRET=""
WOODPECKER_GITLAB="false"
WOODPECKER_GITLAB_URL="http://localhost:8090"
WOODPECKER_GITLAB_CLIENT=""
WOODPECKER_GITLAB_SECRET=""
WOODPECKER_GITEA="false"
WOODPECKER_GITEA_URL="http://localhost:3000"
WOODPECKER_GITEA_CLIENT=""
WOODPECKER_GITEA_SECRET=""
WOODPECKER_ADMIN="admin"
WOODPECKER_OPEN="false"
WOODPECKER_ORGS=""
{{ end }}
EOF
        destination = "local/woodpecker.env"
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
