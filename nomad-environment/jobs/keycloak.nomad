job "keycloak-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "keycloak" {
    count = 1

    network {
      port "http" {
        static = 8070
      }
    }

    volume "keycloak-data" {
      type      = "host"
      read_only = false
      source    = "keycloak-data"
    }

    task "keycloak" {
      driver = "docker"

      config {
        image = "quay.io/keycloak/keycloak:latest"
        ports = ["http"]
        
        command = "/opt/keycloak/bin/kc.sh"
        args = ["start-dev"]
        
        volumes = [
          "keycloak-data:/opt/keycloak/data"
        ]
      }

      env {
        # Admin user configuration
        KEYCLOAK_ADMIN = "admin"
        KEYCLOAK_ADMIN_PASSWORD = "admin123"
        
        # Database configuration (using H2 for development)
        KC_DB = "h2-file"
        KC_DB_URL = "jdbc:h2:file:/opt/keycloak/data/keycloak"
        
        # Server configuration
        KC_HTTP_PORT = "8070"
        KC_HOSTNAME_STRICT = "false"
        KC_HOSTNAME_STRICT_HTTPS = "false"
        KC_HTTP_ENABLED = "true"
        
        # Development mode settings
        KC_CACHE = "local"
        KC_PROXY = "edge"
        
        # Logging
        KC_LOG_LEVEL = "INFO"
        KC_LOG_CONSOLE_OUTPUT = "default"
        
        # Security settings (relaxed for development)
        KC_HOSTNAME_STRICT_BACKCHANNEL = "false"
      }

      template {
        data = <<EOF
# Keycloak realm configuration
# This will be used to create a default realm for development
{
  "realm": "development",
  "enabled": true,
  "displayName": "Development Realm",
  "registrationAllowed": true,
  "resetPasswordAllowed": true,
  "rememberMe": true,
  "verifyEmail": false,
  "loginWithEmailAllowed": true,
  "duplicateEmailsAllowed": false,
  "clients": [
    {
      "clientId": "development-app",
      "enabled": true,
      "clientAuthenticatorType": "client-secret",
      "secret": "development-secret",
      "redirectUris": ["http://localhost:*"],
      "webOrigins": ["http://localhost:*"],
      "standardFlowEnabled": true,
      "implicitFlowEnabled": true,
      "directAccessGrantsEnabled": true,
      "publicClient": false
    }
  ],
  "users": [
    {
      "username": "testuser",
      "enabled": true,
      "email": "test@example.com",
      "firstName": "Test",
      "lastName": "User",
      "credentials": [
        {
          "type": "password",
          "value": "test123",
          "temporary": false
        }
      ]
    }
  ]
}
EOF
        destination = "local/realm-config.json"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }

      service {
        name = "keycloak"
        port = "http"

        check {
          type     = "http"
          path     = "/health/ready"
          interval = "30s"
          timeout  = "10s"
        }
      }
    }
  }
}
