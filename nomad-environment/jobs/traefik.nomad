job "traefik" {
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      port "http" {
        static = 80
      }
      port "admin" {
        static = 8079
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v2.9"
        ports = ["http", "admin"]
        
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ]
        
        mount {
          type   = "bind"
          source = "local/traefik.yml"
          target = "/etc/traefik/traefik.yml"
        }
        
        mount {
          type   = "bind"
          source = "local/dynamic.yml"
          target = "/etc/traefik/dynamic.yml"
        }
      }

      template {
        data = <<EOF
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
  admin:
    address: ":8079"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: "nomad"
  file:
    filename: "/etc/traefik/dynamic.yml"
    watch: true

log:
  level: INFO

accessLog: {}

metrics:
  prometheus:
    addEntryPointsLabels: true
    addServicesLabels: true
EOF
        destination = "local/traefik.yml"
      }

      template {
        data = <<EOF
http:
  routers:
    # PHP Server
    php-router:
      rule: "Host(`php.localhost`)"
      service: "php-service"
      entryPoints:
        - "web"
    
    # Node.js API
    nodejs-router:
      rule: "Host(`api.localhost`)"
      service: "nodejs-service"
      entryPoints:
        - "web"
    
    # Grafana Dashboard
    grafana-router:
      rule: "Host(`grafana.localhost`)"
      service: "grafana-service"
      entryPoints:
        - "web"
    
    # Prometheus
    prometheus-router:
      rule: "Host(`prometheus.localhost`)"
      service: "prometheus-service"
      entryPoints:
        - "web"
    
    # Jenkins
    jenkins-router:
      rule: "Host(`jenkins.localhost`)"
      service: "jenkins-service"
      entryPoints:
        - "web"
    
    # RabbitMQ Management
    rabbitmq-router:
      rule: "Host(`rabbitmq.localhost`)"
      service: "rabbitmq-service"
      entryPoints:
        - "web"
    
    # Mattermost
    mattermost-router:
      rule: "Host(`mattermost.localhost`)"
      service: "mattermost-service"
      entryPoints:
        - "web"
    
    # Keycloak
    keycloak-router:
      rule: "Host(`keycloak.localhost`)"
      service: "keycloak-service"
      entryPoints:
        - "web"
    
    # Vault
    vault-router:
      rule: "Host(`vault.localhost`)"
      service: "vault-service"
      entryPoints:
        - "web"
    
    # Nexus
    nexus-router:
      rule: "Host(`nexus.localhost`)"
      service: "nexus-service"
      entryPoints:
        - "web"
    
    # Artifactory
    artifactory-router:
      rule: "Host(`artifactory.localhost`)"
      service: "artifactory-service"
      entryPoints:
        - "web"
    
    # cAdvisor
    cadvisor-router:
      rule: "Host(`cadvisor.localhost`)"
      service: "cadvisor-service"
      entryPoints:
        - "web"
    
    # Java Server
    java-router:
      rule: "Host(`java.localhost`)"
      service: "java-service"
      entryPoints:
        - "web"

  services:
    # Service definitions
    php-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:8080"
    
    nodejs-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:3000"
    
    grafana-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:3001"
    
    prometheus-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:9090"
    
    jenkins-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:8088"
    
    rabbitmq-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:15672"
    
    mattermost-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:8065"
    
    keycloak-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:8070"
    
    vault-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:8200"
    
    nexus-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:8081"
    
    artifactory-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:8082"
    
    cadvisor-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:8083"
    
    java-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:8090"
EOF
        destination = "local/dynamic.yml"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "traefik"
        port = "http"

        check {
          type     = "http"
          path     = "/health"
          interval = "30s"
          timeout  = "10s"
        }
      }
    }
  }
}
