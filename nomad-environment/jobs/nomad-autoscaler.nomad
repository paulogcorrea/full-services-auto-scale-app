job "nomad-autoscaler" {
  datacenters = ["dc1"]
  type        = "service"

  group "autoscaler" {
    count = 1

    network {
      port "http" {
        static = 8080
      }
    }

    task "autoscaler" {
      driver = "docker"

      config {
        image = "hashicorp/nomad-autoscaler:0.4.0"
        ports = ["http"]
        
        args = [
          "agent",
          "-config=/etc/nomad-autoscaler/config.hcl",
          "-log-level=INFO",
          "-log-json=false"
        ]

        mount {
          type   = "bind"
          source = "local/config.hcl"
          target = "/etc/nomad-autoscaler/config.hcl"
        }

        mount {
          type   = "bind"
          source = "local/policies"
          target = "/etc/nomad-autoscaler/policies"
        }
      }

      template {
        data = <<EOF
# Nomad Autoscaler Configuration
datacenter = "dc1"
log_level  = "INFO"
log_json   = false

# Nomad client configuration
nomad {
  address = "http://host.docker.internal:4646"
}

# Prometheus APM configuration for metrics
apm "prometheus" {
  driver = "prometheus"
  config = {
    address = "http://host.docker.internal:9090"
  }
}

# Target scaler configuration for Nomad
target_scaler "nomad" {
  driver = "nomad"
  config = {
    address = "http://host.docker.internal:4646"
  }
}

# Strategy plugins
strategy "target-value" {
  driver = "target-value"
}

strategy "threshold" {
  driver = "threshold"
}

strategy "fixed-value" {
  driver = "fixed-value"
}

# Policy configuration directory
policy_dir = "/etc/nomad-autoscaler/policies"

# HTTP API configuration
http {
  bind_address = "0.0.0.0"
  bind_port    = 8080
}

# Telemetry configuration
telemetry {
  prometheus_metrics = true
  disable_hostname   = true
}
EOF
        destination = "local/config.hcl"
      }

      # Policy directory structure
      template {
        data = <<EOF
# This directory contains autoscaling policies
# Each .hcl file represents a scaling policy for a service
EOF
        destination = "local/policies/README.md"
      }

      # CPU-based scaling policy for Node.js service
      template {
        data = <<EOF
scaling "nodejs_cpu_scaling" {
  enabled = true
  min     = 1
  max     = 5

  policy {
    cooldown            = "2m"
    evaluation_interval = "10s"

    check "avg_cpu" {
      source = "prometheus"
      query  = "avg(nomad_client_allocs_cpu_total_percent{job=\"nodejs-server\"})"

      strategy "target-value" {
        target = 70
      }
    }
  }

  target {
    Namespace = "default"
    Job       = "nodejs-server"
    Group     = "nodejs"
  }
}
EOF
        destination = "local/policies/nodejs-cpu.hcl"
      }

      # Memory-based scaling policy for Redis
      template {
        data = <<EOF
scaling "redis_memory_scaling" {
  enabled = true
  min     = 1
  max     = 3

  policy {
    cooldown            = "3m"
    evaluation_interval = "15s"

    check "avg_memory" {
      source = "prometheus"
      query  = "avg(nomad_client_allocs_memory_usage{job=\"redis-server\"})"

      strategy "target-value" {
        target = 80
      }
    }
  }

  target {
    Namespace = "default"
    Job       = "redis-server"
    Group     = "redis"
  }
}
EOF
        destination = "local/policies/redis-memory.hcl"
      }

      # Request-based scaling policy for PHP service
      template {
        data = <<EOF
scaling "php_request_scaling" {
  enabled = true
  min     = 1
  max     = 10

  policy {
    cooldown            = "1m"
    evaluation_interval = "30s"

    check "req_per_second" {
      source = "prometheus"
      query  = "rate(nginx_http_requests_total{job=\"php-server\"}[5m])"

      strategy "target-value" {
        target = 100
      }
    }
  }

  target {
    Namespace = "default"
    Job       = "php-server"
    Group     = "php"
  }
}
EOF
        destination = "local/policies/php-requests.hcl"
      }

      # Generic CPU scaling policy for Java applications
      template {
        data = <<EOF
scaling "java_cpu_scaling" {
  enabled = true
  min     = 1
  max     = 8

  policy {
    cooldown            = "2m"
    evaluation_interval = "10s"

    check "avg_cpu" {
      source = "prometheus"
      query  = "avg(nomad_client_allocs_cpu_total_percent{job=\"java-server\"})"

      strategy "target-value" {
        target = 75
      }
    }
  }

  target {
    Namespace = "default"
    Job       = "java-server"
    Group     = "java"
  }
}
EOF
        destination = "local/policies/java-cpu.hcl"
      }

      # Database connection scaling for PostgreSQL
      template {
        data = <<EOF
scaling "postgres_connection_scaling" {
  enabled = true
  min     = 1
  max     = 3

  policy {
    cooldown            = "5m"
    evaluation_interval = "30s"

    check "active_connections" {
      source = "prometheus"
      query  = "pg_stat_activity_count{job=\"postgresql-server\"}"

      strategy "threshold" {
        upper_bound = 80
        lower_bound = 20
      }
    }
  }

  target {
    Namespace = "default"
    Job       = "postgresql-server"
    Group     = "postgres"
  }
}
EOF
        destination = "local/policies/postgres-connections.hcl"
      }

      # Time-based scaling policy for batch processing
      template {
        data = <<EOF
scaling "batch_time_scaling" {
  enabled = true
  min     = 0
  max     = 5

  policy {
    cooldown            = "10m"
    evaluation_interval = "1m"

    check "business_hours" {
      source = "prometheus"
      query  = "hour()"

      strategy "threshold" {
        upper_bound = 18  # 6 PM
        lower_bound = 8   # 8 AM
      }
    }
  }

  target {
    Namespace = "default"
    Job       = "batch-processor"
    Group     = "batch"
  }
}
EOF
        destination = "local/policies/batch-time.hcl"
      }

      resources {
        cpu    = 200
        memory = 256
      }

      service {
        name = "nomad-autoscaler"
        port = "http"

        check {
          type     = "http"
          path     = "/v1/health"
          interval = "10s"
          timeout  = "3s"
        }

        tags = [
          "autoscaler",
          "nomad",
          "scaling"
        ]
      }
    }
  }
}
