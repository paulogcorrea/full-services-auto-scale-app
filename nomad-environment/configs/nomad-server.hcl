datacenter = "dc1"
data_dir   = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/nomad-data"
bind_addr  = "127.0.0.1"

advertise {
  http = "127.0.0.1:4646"
  rpc  = "127.0.0.1:4647"
  serf = "127.0.0.1:4648"
}

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
  
  # Host volume definitions for persistent storage
  host_volume "keycloak-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/keycloak-data"
    read_only = false
  }
  
  host_volume "mysql-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/mysql-data"
    read_only = false
  }
  
  host_volume "postgres-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/postgres-data"
    read_only = false
  }
  
  host_volume "mongodb-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/mongodb-data"
    read_only = false
  }
  
  host_volume "redis-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/redis-data"
    read_only = false
  }
  
  host_volume "prometheus-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/prometheus-data"
    read_only = false
  }
  
  host_volume "grafana-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/grafana-data"
    read_only = false
  }
  
  host_volume "loki-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/loki-data"
    read_only = false
  }
  
  host_volume "jenkins-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/jenkins-data"
    read_only = false
  }
  
  host_volume "nexus-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/nexus-data"
    read_only = false
  }
  
  host_volume "artifactory-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/artifactory-data"
    read_only = false
  }
  
  host_volume "sonarqube-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/sonarqube-data"
    read_only = false
  }
  
  host_volume "sonarqube-extensions" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/sonarqube-extensions"
    read_only = false
  }
  
  host_volume "sonarqube-logs" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/sonarqube-logs"
    read_only = false
  }
  
  host_volume "minio-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/minio-data"
    read_only = false
  }
  
  host_volume "mattermost-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/mattermost-data"
    read_only = false
  }
  
  host_volume "mattermost-config" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/mattermost-config"
    read_only = false
  }
  
  host_volume "mattermost-logs" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/mattermost-logs"
    read_only = false
  }
  
  host_volume "zookeeper-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/zookeeper-data"
    read_only = false
  }
  
  host_volume "zookeeper-logs" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/zookeeper-logs"
    read_only = false
  }
  
  host_volume "kafka-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/kafka-data"
    read_only = false
  }
  
  host_volume "rabbitmq-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/rabbitmq-data"
    read_only = false
  }
  
  host_volume "consul-data" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/consul-data"
    read_only = false
  }
  
  host_volume "traefik-certs" {
    path      = "/Users/paulo/projetos/full-services-auto-scale-app/nomad-environment/volumes/traefik-certs"
    read_only = false
  }
}

consul {
  address = "127.0.0.1:8500"
}

ports {
  http = 4646
  rpc  = 4647
  serf = 4648
}
