job "gitlab-ce" {
  datacenters = ["dc1"]
  type        = "service"
  
  group "gitlab" {
    count = 1
    
    # GitLab requires significant resources
    reschedule {
      attempts  = 3
      interval  = "10m"
      delay     = "30s"
      delay_function = "exponential"
      max_delay = "10m"
      unlimited = false
    }
    
    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }
    
    network {
      port "http" {
        static = 8090
      }
      port "https" {
        static = 8443
      }
      port "ssh" {
        static = 2022
      }
    }
    
    volume "gitlab_config" {
      type      = "host"
      read_only = false
      source    = "gitlab_config"
    }
    
    volume "gitlab_logs" {
      type      = "host"
      read_only = false
      source    = "gitlab_logs"
    }
    
    volume "gitlab_data" {
      type      = "host"
      read_only = false
      source    = "gitlab_data"
    }
    
    task "gitlab-ce" {
      driver = "docker"
      
      config {
        image = "gitlab/gitlab-ce:latest"
        
        ports = ["http", "https", "ssh"]
        
        hostname = "gitlab.local"
        
        # Mount volumes for persistence
        mount {
          type   = "volume"
          target = "/etc/gitlab"
          source = "gitlab_config"
        }
        
        mount {
          type   = "volume"
          target = "/var/log/gitlab"
          source = "gitlab_logs"
        }
        
        mount {
          type   = "volume"
          target = "/var/opt/gitlab"
          source = "gitlab_data"
        }
        
        # Shared memory for GitLab
        shm_size = 256000000
      }
      
      env {
        GITLAB_OMNIBUS_CONFIG = <<EOF
external_url 'http://gitlab.local:8090'
gitlab_rails['gitlab_shell_ssh_port'] = 2022
gitlab_rails['time_zone'] = 'UTC'

# PostgreSQL configuration (external)
postgresql['enable'] = false
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'unicode'
gitlab_rails['db_host'] = '${NOMAD_IP_http}'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_database'] = 'gitlab'
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = 'gitlab_password'

# Redis configuration (external)
redis['enable'] = false
gitlab_rails['redis_host'] = '${NOMAD_IP_http}'
gitlab_rails['redis_port'] = 6379

# Disable some services to reduce memory usage
prometheus_monitoring['enable'] = false
grafana['enable'] = false
alertmanager['enable'] = false

# Performance tuning for smaller deployments
unicorn['worker_processes'] = 2
sidekiq['max_concurrency'] = 10

# SMTP configuration (optional)
gitlab_rails['smtp_enable'] = false

# Backup configuration
gitlab_rails['backup_keep_time'] = 604800
gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"

# Security
gitlab_rails['gitlab_signup_enabled'] = true
gitlab_rails['gitlab_default_can_create_group'] = true
gitlab_rails['gitlab_username_changing_enabled'] = false

# Container registry (optional)
registry_external_url 'http://gitlab.local:5050'
gitlab_rails['registry_enabled'] = true
registry['enable'] = true
EOF
      }
      
      resources {
        cpu    = 2000  # 2 CPU cores
        memory = 4096  # 4GB RAM (minimum for GitLab)
      }
      
      service {
        name = "gitlab-ce"
        port = "http"
        
        tags = [
          "gitlab",
          "git",
          "devops",
          "ci-cd",
          "version-control"
        ]
        
        check {
          type     = "http"
          path     = "/-/health"
          interval = "30s"
          timeout  = "10s"
          
          check_restart {
            limit           = 3
            grace           = "30s"
            ignore_warnings = false
          }
        }
      }
      
      service {
        name = "gitlab-ce-ssh"
        port = "ssh"
        
        tags = [
          "gitlab",
          "ssh",
          "git"
        ]
        
        check {
          type     = "tcp"
          interval = "30s"
          timeout  = "5s"
        }
      }
    }
  }
}
