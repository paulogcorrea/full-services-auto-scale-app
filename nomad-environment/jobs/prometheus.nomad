job "prometheus-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "prometheus" {
    count = 1

    network {
      port "http" {
        static = 9090
      }
    }

    volume "prometheus-data" {
      type      = "host"
      read_only = false
      source    = "prometheus-data"
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:latest"
        ports = ["http"]
        
        args = [
          "--config.file=/etc/prometheus/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.console.libraries=/etc/prometheus/console_libraries",
          "--web.console.templates=/etc/prometheus/consoles",
          "--storage.tsdb.retention.time=15d",
          "--web.enable-lifecycle",
          "--web.enable-admin-api"
        ]
        
        volumes = [
          "prometheus-data:/prometheus"
        ]
        
        mount {
          type   = "bind"
          source = "local/prometheus.yml"
          target = "/etc/prometheus/prometheus.yml"
        }
      }

      template {
        data = <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Nomad server metrics
  - job_name: 'nomad'
    static_configs:
      - targets: ['host.docker.internal:4646']
    metrics_path: '/v1/metrics'
    params:
      format: ['prometheus']

  # Node.js application metrics (if metrics endpoint is available)
  - job_name: 'nodejs-app'
    static_configs:
      - targets: ['host.docker.internal:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  # Jenkins metrics (if prometheus plugin is installed)
  - job_name: 'jenkins'
    static_configs:
      - targets: ['host.docker.internal:8088']
    metrics_path: '/prometheus/'
    scrape_interval: 30s

  # RabbitMQ metrics (management plugin provides prometheus endpoint)
  - job_name: 'rabbitmq'
    static_configs:
      - targets: ['host.docker.internal:15692']
    metrics_path: '/metrics'
    scrape_interval: 30s

  # MySQL metrics (if mysqld_exporter is running)
  - job_name: 'mysql'
    static_configs:
      - targets: ['host.docker.internal:9104']
    scrape_interval: 30s

  # PostgreSQL metrics (if postgres_exporter is running)
  - job_name: 'postgres'
    static_configs:
      - targets: ['host.docker.internal:9187']
    scrape_interval: 30s

  # Docker container metrics
  - job_name: 'docker'
    static_configs:
      - targets: ['host.docker.internal:9323']
    scrape_interval: 30s

  # cAdvisor for container metrics
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['host.docker.internal:8083']
    metrics_path: '/metrics'
    scrape_interval: 30s

  # Node exporter for system metrics
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['host.docker.internal:9100']
    scrape_interval: 30s

  # Vault metrics
  - job_name: 'vault'
    static_configs:
      - targets: ['host.docker.internal:8200']
    metrics_path: '/v1/sys/metrics'
    params:
      format: ['prometheus']
    scrape_interval: 30s

  # Keycloak metrics (if metrics are enabled)
  - job_name: 'keycloak'
    static_configs:
      - targets: ['host.docker.internal:8070']
    metrics_path: '/metrics'
    scrape_interval: 30s

  # Mattermost metrics (if available)
  - job_name: 'mattermost'
    static_configs:
      - targets: ['host.docker.internal:8065']
    metrics_path: '/metrics'
    scrape_interval: 30s

  # Nexus metrics (if available)
  - job_name: 'nexus'
    static_configs:
      - targets: ['host.docker.internal:8081']
    metrics_path: '/service/metrics/prometheus'
    scrape_interval: 30s

  # Artifactory metrics (if available)
  - job_name: 'artifactory'
    static_configs:
      - targets: ['host.docker.internal:8082']
    metrics_path: '/artifactory/api/v1/metrics'
    scrape_interval: 30s
EOF
        destination = "local/prometheus.yml"
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      service {
        name = "prometheus"
        port = "http"

        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
