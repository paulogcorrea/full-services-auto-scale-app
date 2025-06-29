job "promtail" {
  datacenters = ["dc1"]
  type        = "system"

  group "promtail" {
    count = 1

    network {
      port "http" {
        static = 9080
      }
    }

    task "promtail" {
      driver = "docker"

      config {
        image = "grafana/promtail:2.4.2"
        ports = ["http"]
        
        args = [
          "-config.file=/etc/promtail/config.yml"
        ]
        
        volumes = [
          "/var/log:/var/log:ro",
          "/var/lib/docker/containers:/var/lib/docker/containers:ro"
        ]
        
        mount {
          type   = "bind"
          source = "local/promtail-config.yml"
          target = "/etc/promtail/config.yml"
        }
      }

      template {
        data = <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://host.docker.internal:3100/loki/api/v1/push

scrape_configs:
  # Docker containers logs
  - job_name: containers
    static_configs:
      - targets:
          - localhost
        labels:
          job: containerlogs
          __path__: /var/lib/docker/containers/*/*log

    pipeline_stages:
      - json:
          expressions:
            output: log
            stream: stream
            attrs:
      - json:
          expressions:
            tag:
          source: attrs
      - regex:
          expression: (?P<container_name>(?:[^|]*))[^|]*(?P<anything>.*)
          source: tag
      - timestamp:
          format: RFC3339Nano
          source: time
      - labels:
          stream:
          container_name:
      - output:
          source: output

  # System logs
  - job_name: syslog
    static_configs:
      - targets:
          - localhost
        labels:
          job: syslog
          __path__: /var/log/system.log*

  # Nomad logs (if available)
  - job_name: nomad
    static_configs:
      - targets:
          - localhost
        labels:
          job: nomad
          __path__: /var/log/nomad/*.log

  # Application specific logs
  - job_name: application-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: application
          __path__: /var/log/applications/*.log

  # Custom log paths
  - job_name: custom-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: custom
          __path__: /var/log/custom/*.log
EOF
        destination = "local/promtail-config.yml"
      }

      resources {
        cpu    = 200
        memory = 256
      }

      service {
        name = "promtail"
        port = "http"

        check {
          type     = "http"
          path     = "/metrics"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
