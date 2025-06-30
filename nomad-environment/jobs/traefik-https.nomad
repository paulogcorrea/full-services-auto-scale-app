job "traefik-https" {
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      port "http" {
        static = 80
      }
      port "https" {
        static = 443
      }
      port "admin" {
        static = 8079
      }
    }

    volume "traefik-certs" {
      type      = "host"
      read_only = false
      source    = "traefik-certs"
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v2.9"
        ports = ["http", "https", "admin"]
        
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro",
          "traefik-certs:/certs"
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
    http:
      redirections:
        entrypoint:
          to: websecure
          scheme: https
          permanent: true
  websecure:
    address: ":443"
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
        - "websecure"
      tls:
        options: "default"
    
    # Node.js API
    nodejs-router:
      rule: "Host(`api.localhost`)"
      service: "nodejs-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"
    
    # Grafana Dashboard
    grafana-router:
      rule: "Host(`grafana.localhost`)"
      service: "grafana-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"
    
    # Prometheus
    prometheus-router:
      rule: "Host(`prometheus.localhost`)"
      service: "prometheus-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"
    
    # Jenkins
    jenkins-router:
      rule: "Host(`jenkins.localhost`)"
      service: "jenkins-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"
    
    # RabbitMQ Management
    rabbitmq-router:
      rule: "Host(`rabbitmq.localhost`)"
      service: "rabbitmq-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"
    
    # Mattermost
    mattermost-router:
      rule: "Host(`mattermost.localhost`)"
      service: "mattermost-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"
    
    # Keycloak
    keycloak-router:
      rule: "Host(`keycloak.localhost`)"
      service: "keycloak-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"
    
    # Vault
    vault-router:
      rule: "Host(`vault.localhost`)"
      service: "vault-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"
    
    # Nexus
    nexus-router:
      rule: "Host(`nexus.localhost`)"
      service: "nexus-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"
    
    # Artifactory
    artifactory-router:
      rule: "Host(`artifactory.localhost`)"
      service: "artifactory-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"
    
    # cAdvisor
    cadvisor-router:
      rule: "Host(`cadvisor.localhost`)"
      service: "cadvisor-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"
    
    # Java Server
    java-router:
      rule: "Host(`java.localhost`)"
      service: "java-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"
    
    # MinIO Console
    minio-router:
      rule: "Host(`minio.localhost`)"
      service: "minio-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"
    
    # SonarQube
    sonarqube-router:
      rule: "Host(`sonarqube.localhost`)"
      service: "sonarqube-service"
      entryPoints:
        - "websecure"
      tls:
        options: "default"

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
    
    minio-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:9001"
    
    sonarqube-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:9002"

tls:
  options:
    default:
      sslStrategies:
        - "tls.SniStrict"
      minVersion: "VersionTLS12"
      cipherSuites:
        - "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
        - "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
        - "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
        - "TLS_RSA_WITH_AES_256_GCM_SHA384"
        - "TLS_RSA_WITH_AES_128_GCM_SHA256"

  certificates:
    - certFile: "/certs/server-cert.pem"
      keyFile: "/certs/server-key.pem"
      stores:
        - "default"
EOF
        destination = "local/dynamic.yml"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "traefik-https"
        port = "https"

        check {
          type     = "tcp"
          interval = "30s"
          timeout  = "10s"
        }
      }
    }
  }
}
