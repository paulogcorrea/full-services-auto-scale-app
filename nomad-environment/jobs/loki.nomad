job "loki-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "loki" {
    count = 1

    network {
      port "http" {
        static = 3100
      }
    }

    volume "loki-data" {
      type      = "host"
      read_only = false
      source    = "loki-data"
    }

    task "loki" {
      driver = "docker"

      config {
        image = "grafana/loki:2.4.2"
        ports = ["http"]
        
        args = [
          "-config.file=/etc/loki/local-config.yml"
        ]
        
        volumes = [
          "loki-data:/loki"
        ]
        
        mount {
          type   = "bind"
          source = "local/loki-config.yml"
          target = "/etc/loki/local-config.yml"
        }
      }

      template {
        data = """
server:
  http_listen_port: 3100

memberlist:
  join_members: []

storage_config:
  boltdb:
    directory: /loki/index
  filesystem:
    directory: /loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
    final_sleep: 0s
  chunk_idle_period: 15m
  chunk_retain_period: 30s
  max_transfer_retries: 0
  flush_checkpoint_delay: 0s

schema_config:
  configs:
  - from: 2022-09-01
    store: boltdb-shipper
    object_store: filesystem
    schema: v11
    index:
      prefix: index_
      period: 24h

ruler:
  alertmanager_url: ""
        """
        destination = "local/loki-config.yml"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "loki"
        port = "http"

        check {
          type     = "http"
          path     = "/ready"
          interval = "30s"
          timeout  = "10s"
        }
      }
    }
  }
}
