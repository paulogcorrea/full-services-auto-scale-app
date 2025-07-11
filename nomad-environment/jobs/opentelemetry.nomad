job "opentelemetry-collector" {
  datacenters = ["dc1"]
  type        = "service"

  group "otel-collector" {
    count = 1

    network {
      port "otlp-grpc" {
        static = 4317
      }
      port "otlp-http" {
        static = 4318
      }
      port "jaeger-grpc" {
        static = 14250
      }
      port "jaeger-thrift" {
        static = 14268
      }
      port "zipkin" {
        static = 9411
      }
      port "prometheus" {
        static = 8888
      }
      port "health" {
        static = 13133
      }
    }


    task "otel-collector" {
      driver = "docker"

      config {
        image = "otel/opentelemetry-collector-contrib:latest"
        ports = ["otlp-grpc", "otlp-http", "jaeger-grpc", "jaeger-thrift", "zipkin", "prometheus", "health"]
        
args = [
          "--config=/etc/otel-collector-config/otel-collector-config.yaml"
        ]
        
        mount {
          type   = "bind"
          source = "local/otel-collector-config.yaml"
          target = "/etc/otel-collector-config/otel-collector-config.yaml"
        }
      }

      env {
        OTEL_RESOURCE_ATTRIBUTES = "service.name=otel-collector,service.version=latest"
      }

      template {
        data = <<EOF
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  jaeger:
    protocols:
      grpc:
        endpoint: 0.0.0.0:14250
      thrift_http:
        endpoint: 0.0.0.0:14268
  zipkin:
    endpoint: 0.0.0.0:9411
  prometheus:
    config:
      scrape_configs:
        - job_name: 'otel-collector'
          scrape_interval: 10s
          static_configs:
            - targets: ['0.0.0.0:8888']

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    limit_mib: 512

exporters:
  # Prometheus metrics exporter
  prometheus:
    endpoint: "0.0.0.0:8888"
    const_labels:
      environment: "dev"
  
  # Jaeger tracing exporter (if Jaeger is running)
  jaeger:
    endpoint: host.docker.internal:14250
    tls:
      insecure: true
  
  # Logging exporter for debugging
  logging:
    loglevel: debug
    sampling_initial: 5
    sampling_thereafter: 200
  
  # File exporter for local storage
  file:
    path: /tmp/otel-traces.json
    format: json

service:
  pipelines:
    traces:
      receivers: [otlp, jaeger, zipkin]
      processors: [memory_limiter, batch]
      exporters: [logging, jaeger, file]
    
    metrics:
      receivers: [otlp, prometheus]
      processors: [memory_limiter, batch]
      exporters: [prometheus, logging]
    
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [logging, file]

  extensions:
    health_check:
      endpoint: 0.0.0.0:13133
    pprof:
      endpoint: 0.0.0.0:1777
    zpages:
      endpoint: 0.0.0.0:55679

  telemetry:
    logs:
      level: info
    metrics:
      address: 0.0.0.0:8888
EOF
        destination = "local/otel-collector-config.yaml"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "opentelemetry-collector"
        port = "health"

        check {
          type     = "http"
          path     = "/"
          interval = "30s"
          timeout  = "10s"
        }
        
        tags = [
          "otel",
          "telemetry",
          "tracing",
          "metrics"
        ]
      }

      service {
        name = "opentelemetry-otlp-grpc"
        port = "otlp-grpc"
        tags = ["otel", "otlp", "grpc"]
      }

      service {
        name = "opentelemetry-otlp-http"
        port = "otlp-http"
        tags = ["otel", "otlp", "http"]
      }

      service {
        name = "opentelemetry-jaeger"
        port = "jaeger-grpc"
        tags = ["otel", "jaeger", "tracing"]
      }

      service {
        name = "opentelemetry-zipkin"
        port = "zipkin"
        tags = ["otel", "zipkin", "tracing"]
      }

      service {
        name = "opentelemetry-metrics"
        port = "prometheus"
        tags = ["otel", "prometheus", "metrics"]
      }
    }
  }
}
