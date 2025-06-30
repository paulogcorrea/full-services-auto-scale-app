job "grafana-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "grafana" {
    count = 1

    network {
      port "http" {
        static = 3001
      }
    }

    volume "grafana-data" {
      type      = "host"
      read_only = false
      source    = "grafana-data"
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:latest"
        ports = ["http"]
        
        volumes = [
          "grafana-data:/var/lib/grafana"
        ]
        
        mount {
          type   = "bind"
          source = "local/grafana.ini"
          target = "/etc/grafana/grafana.ini"
        }
        
        mount {
          type   = "bind"
          source = "local/datasources.yml"
          target = "/etc/grafana/provisioning/datasources/datasources.yml"
        }
        
        mount {
          type   = "bind"
          source = "local/dashboards.yml"
          target = "/etc/grafana/provisioning/dashboards/dashboards.yml"
        }
      }

      env {
        GF_SECURITY_ADMIN_PASSWORD = "${GRAFANA_ADMIN_PASSWORD}"
        GF_USERS_ALLOW_SIGN_UP = "false"
        GF_INSTALL_PLUGINS = "grafana-piechart-panel"
      }

      template {
        data = <<EOF
[server]
http_port = 3001
domain = localhost

[database]
type = sqlite3
path = /var/lib/grafana/grafana.db

[session]
provider = file
provider_config = sessions

[analytics]
reporting_enabled = false
check_for_updates = true

[security]
admin_user = ${GRAFANA_ADMIN_USER}
admin_password = ${GRAFANA_ADMIN_PASSWORD}
secret_key = SW2YcwTIb9zpOOhoPsMm

[snapshots]
external_enabled = false

[dashboards]
default_home_dashboard_path = /etc/grafana/provisioning/dashboards/overview.json

[auth]
disable_login_form = false

[auth.anonymous]
enabled = false

[log]
mode = console
level = info

[paths]
data = /var/lib/grafana
logs = /var/log/grafana
plugins = /var/lib/grafana/plugins
provisioning = /etc/grafana/provisioning
EOF
        destination = "local/grafana.ini"
      }

      template {
        data = <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://host.docker.internal:9090
    isDefault: true
    editable: true

  - name: Loki
    type: loki
    access: proxy
    url: http://host.docker.internal:3100
    editable: true
    jsonData:
      maxLines: 1000
EOF
        destination = "local/datasources.yml"
      }

      template {
        data = <<EOF
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF
        destination = "local/dashboards.yml"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "grafana"
        port = "http"

        check {
          type     = "http"
          path     = "/api/health"
          interval = "30s"
          timeout  = "10s"
        }
      }
    }
  }
}
