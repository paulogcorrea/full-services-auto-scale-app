#!/bin/bash

# Nomad Environment Manager
# This script starts a Nomad server and allows selection of services to deploy

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NOMAD_DATA_DIR="$(pwd)/nomad-data"
NOMAD_CONFIG_FILE="$(pwd)/configs/nomad-server.hcl"
NOMAD_JOBS_DIR="$(pwd)/jobs"
NOMAD_PORT=4646

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Function to get service name by key
get_service_name() {
    case $1 in
        "prometheus") echo "Prometheus Metrics Server" ;;
        "grafana") echo "Grafana Visualization Dashboard" ;;
        "loki") echo "Loki Log Aggregation" ;;
        "promtail") echo "Promtail Log Collection Agent" ;;
        "node-exporter") echo "Node Exporter (System Metrics)" ;;
        "cadvisor") echo "cAdvisor (Container Metrics)" ;;
        "mysql") echo "MySQL Database Server" ;;
        "postgresql") echo "PostgreSQL Database Server" ;;
        "mongodb") echo "MongoDB Document Database" ;;
        "redis") echo "Redis In-Memory Data Store" ;;
        "zookeeper") echo "Apache ZooKeeper" ;;
        "kafka") echo "Apache Kafka Event Streaming" ;;
        "rabbitmq") echo "RabbitMQ Message Broker" ;;
        "php") echo "PHP Server" ;;
        "nodejs") echo "Node.js Backend API" ;;
        "java") echo "Java Application Server" ;;
        "jenkins") echo "Jenkins CI/CD Server" ;;
        "sonarqube") echo "SonarQube Code Quality Analysis" ;;
        "nexus") echo "Sonatype Nexus Repository" ;;
        "artifactory") echo "JFrog Artifactory" ;;
        "vault") echo "HashiCorp Vault" ;;
        "keycloak") echo "Keycloak Identity Management" ;;
        "minio") echo "MinIO S3-Compatible Object Storage" ;;
        "mattermost") echo "Mattermost Collaboration Tool" ;;
        "traefik") echo "Traefik Reverse Proxy" ;;
        "traefik-https") echo "Traefik Reverse Proxy (HTTPS)" ;;
        *) echo "Unknown Service" ;;
    esac
}

# Function to get service key by number
get_service_key() {
    case $1 in
        1) echo "prometheus" ;;
        2) echo "grafana" ;;
        3) echo "loki" ;;
        4) echo "promtail" ;;
        5) echo "node-exporter" ;;
        6) echo "cadvisor" ;;
        7) echo "mysql" ;;
        8) echo "postgresql" ;;
        9) echo "mongodb" ;;
        10) echo "redis" ;;
        11) echo "zookeeper" ;;
        12) echo "kafka" ;;
        13) echo "rabbitmq" ;;
        14) echo "php" ;;
        15) echo "nodejs" ;;
        16) echo "java" ;;
        17) echo "jenkins" ;;
        18) echo "sonarqube" ;;
        19) echo "nexus" ;;
        20) echo "artifactory" ;;
        21) echo "vault" ;;
        22) echo "keycloak" ;;
        23) echo "minio" ;;
        24) echo "mattermost" ;;
        25) echo "traefik" ;;
        26) echo "traefik-https" ;;
        *) echo "" ;;
    esac
}

# Function to check if Nomad is installed
check_nomad_installation() {
    if ! command -v nomad &> /dev/null; then
        print_error "Nomad is not installed. Please install it first."
        echo "You can install it using:"
        echo "  brew tap hashicorp/tap"
        echo "  brew install hashicorp/tap/nomad"
        exit 1
    fi
}

# Function to check if Consul is installed
check_consul_installation() {
    if ! command -v consul &> /dev/null; then
        print_error "Consul is not installed. Please install it first."
        echo "You can install it using:"
        echo "  brew tap hashicorp/tap"
        echo "  brew install hashicorp/tap/consul"
        exit 1
    fi
}

# Function to check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Function to start Consul server
start_consul_server() {
    # Check if Consul is already running
    if consul members &> /dev/null; then
        print_status "Consul server is already running"
        return 0
    fi
    
    print_status "Starting Consul server..."
    
    # Create data directory
    mkdir -p "$(pwd)/consul-data"
    
    # Start Consul in development mode (background)
    nohup consul agent -dev \
        -client=0.0.0.0 \
        -bind=127.0.0.1 \
        -ui \
        -data-dir="$(pwd)/consul-data" \
        > consul.log 2>&1 &
    
    echo $! > consul.pid
    
    # Wait for Consul to start
    print_status "Waiting for Consul to start..."
    sleep 3
    
    # Check if Consul is running
    if consul members &> /dev/null; then
        print_status "Consul server started successfully!"
        print_status "Consul UI available at: http://localhost:8500"
    else
        print_error "Failed to start Consul server"
        exit 1
    fi
}

# Function to start Nomad server with Consul integration
start_nomad_server() {
    print_status "Starting Nomad server with Consul integration..."
    
    # Create data directory
    mkdir -p "$NOMAD_DATA_DIR"
    
    # Check if configuration file exists
    if [ ! -f "$NOMAD_CONFIG_FILE" ]; then
        print_error "Nomad configuration file not found: $NOMAD_CONFIG_FILE"
        exit 1
    fi
    
    # Start Nomad with configuration file (background)
    nohup nomad agent -config="$NOMAD_CONFIG_FILE" \
        > nomad.log 2>&1 &
    
    echo $! > nomad.pid
    
    # Wait for Nomad to start
    print_status "Waiting for Nomad to start..."
    sleep 5
    
    # Check if Nomad is running
    if nomad node status &> /dev/null; then
        print_status "Nomad server started successfully!"
        print_status "Nomad UI available at: http://localhost:4646"
    else
        print_error "Failed to start Nomad server"
        exit 1
    fi
}

# Function to stop Consul server
stop_consul_server() {
    if [ -f consul.pid ]; then
        PID=$(cat consul.pid)
        if ps -p $PID > /dev/null; then
            print_status "Stopping Consul server (PID: $PID)..."
            kill $PID
            rm consul.pid
            print_status "Consul server stopped"
        else
            print_warning "Consul server not running"
            rm consul.pid
        fi
    else
        print_warning "No Consul PID file found"
    fi
}

# Function to stop Nomad server
stop_nomad_server() {
    if [ -f nomad.pid ]; then
        PID=$(cat nomad.pid)
        if ps -p $PID > /dev/null; then
            print_status "Stopping Nomad server (PID: $PID)..."
            kill $PID
            rm nomad.pid
            print_status "Nomad server stopped"
        else
            print_warning "Nomad server not running"
            rm nomad.pid
        fi
    else
        print_warning "No Nomad PID file found"
    fi
}

# Function to show service menu
show_service_menu() {
    print_header "================== Available Services (26 Total) =================="
    echo
    
    print_header "📊 OBSERVABILITY & MONITORING (6 services)"
    echo " 1) Prometheus Metrics Server (prometheus)"
    echo " 2) Grafana Visualization Dashboard (grafana)"
    echo " 3) Loki Log Aggregation (loki)"
    echo " 4) Promtail Log Collection Agent (promtail)"
    echo " 5) Node Exporter (System Metrics) (node-exporter)"
    echo " 6) cAdvisor (Container Metrics) (cadvisor)"
    echo
    
    print_header "💾 DATABASES (4 services)"
    echo " 7) MySQL Database Server (mysql)"
    echo " 8) PostgreSQL Database Server (postgresql)"
    echo " 9) MongoDB Document Database (mongodb)"
    echo "10) Redis In-Memory Data Store (redis)"
    echo
    
    print_header "🔄 MESSAGING & STREAMING (3 services)"
    echo "11) Apache ZooKeeper (zookeeper)"
    echo "12) Apache Kafka Event Streaming (kafka)"
    echo "13) RabbitMQ Message Broker (rabbitmq)"
    echo
    
    print_header "🌐 WEB SERVERS & APIs (3 services)"
    echo "14) PHP Server (php)"
    echo "15) Node.js Backend API (nodejs)"
    echo "16) Java Application Server (java)"
    echo
    
    print_header "🔧 DEVELOPMENT TOOLS (4 services)"
    echo "17) Jenkins CI/CD Server (jenkins)"
    echo "18) SonarQube Code Quality Analysis (sonarqube)"
    echo "19) Sonatype Nexus Repository (nexus)"
    echo "20) JFrog Artifactory (artifactory)"
    echo
    
    print_header "🔐 SECURITY & STORAGE (4 services)"
    echo "21) HashiCorp Vault (vault)"
    echo "22) Keycloak Identity Management (keycloak)"
    echo "23) MinIO S3-Compatible Object Storage (minio)"
    echo "24) Mattermost Collaboration Tool (mattermost)"
    echo
    
    print_header "🌍 NETWORKING & PROXY (2 services)"
    echo "25) Traefik Reverse Proxy (traefik)"
    echo "26) Traefik Reverse Proxy (HTTPS) (traefik-https)"
    echo
    
    print_header "⚙️  ACTIONS"
    echo "27) Deploy Custom Application"
    echo "28) Deploy Multiple Services"
    echo "29) Show All Running Services"
    echo "30) Stop Specific Service"
    echo "31) Stop All Services"
    echo " 0) Exit"
    echo
}

# Function to load secrets from Ansible Vault
load_secrets() {
    echo -e "${BLUE}🔐 Loading encrypted secrets...${NC}"
    if [[ -f "scripts/load-secrets.sh" ]]; then
        # Source the secrets script to load environment variables
        # Don't suppress output so user can enter vault password
        if source scripts/load-secrets.sh; then
            echo -e "${GREEN}✅ Secrets loaded successfully${NC}"
        else
            echo -e "${YELLOW}⚠️  Failed to load secrets. Using default configuration.${NC}"
            echo -e "${YELLOW}💡 You can continue with default credentials or exit and fix the issue.${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Secrets file not found. Using default configuration.${NC}"
        echo -e "${YELLOW}💡 Run 'source scripts/load-secrets.sh' manually if you want to load secrets later.${NC}"
    fi
}

# Function to ensure Nomad and Consul are running
ensure_nomad_running() {
    # Check if Nomad is already running
    if nomad node status &> /dev/null; then
        print_status "Nomad server is already running"
        return 0
    fi
    
    print_header "Starting Nomad Environment Manager"
    
    # Pre-flight checks
    check_nomad_installation
    check_consul_installation
    check_docker
    
    # Start Consul first (required for service discovery)
    start_consul_server
    
    # Start Nomad server with Consul integration
    start_nomad_server
}

# Function to deploy a service
deploy_service() {
    local service_key=$1
    local service_name=$(get_service_name "$service_key")
    local job_file="$NOMAD_JOBS_DIR/${service_key}.nomad"
    
    # Ensure Nomad is running before deployment
    ensure_nomad_running
    
    if [ -f "$job_file" ]; then
        print_status "Deploying $service_name..."
        if nomad job run "$job_file"; then
            print_status "$service_name deployed successfully!"
        else
            print_error "Failed to deploy $service_name"
        fi
    else
        print_error "Job file not found: $job_file"
    fi
}

# Function to show deployed jobs
show_deployed_jobs() {
    # Ensure Nomad is running to show jobs
    ensure_nomad_running
    
    print_header "================== Deployed Jobs =================="
    nomad job status
    echo
}

# Function to deploy multiple services
deploy_multiple_services() {
    print_header "================== Deploy Multiple Services =================="
    echo "Enter service numbers separated by spaces (e.g., '1 2 7 15')"
    echo "Or enter service names separated by spaces (e.g., 'prometheus grafana mysql')"
    echo
    
    read -p "Services to deploy: " services_input
    
    if [ -z "$services_input" ]; then
        print_warning "No services specified."
        return
    fi
    
    print_status "Deploying selected services..."
    echo
    
    for item in $services_input; do
        # Check if item is a number
        if [[ "$item" =~ ^[0-9]+$ ]]; then
            # It's a number, get service by number
            if [ "$item" -ge 1 ] && [ "$item" -le 26 ]; then
                local selected_service=$(get_service_key "$item")
                if [ -n "$selected_service" ]; then
                    deploy_service "$selected_service"
                else
                    print_error "Invalid service number: $item"
                fi
            else
                print_error "Invalid service number: $item (must be 1-26)"
            fi
        else
            # It's a name, check if it exists
            local service_name=$(get_service_name "$item")
            if [ "$service_name" != "Unknown Service" ]; then
                deploy_service "$item"
            else
                print_error "Unknown service: $item"
            fi
        fi
        echo
    done
    
    print_status "Multiple service deployment completed!"
    show_deployed_jobs
}

# Function to stop a specific service
stop_specific_service() {
    print_header "================== Stop Specific Service =================="
    echo "Enter the service name or number to stop:"
    echo
    
    # Show currently running services
    print_status "Currently running services:"
    if nomad node status &> /dev/null; then
        nomad job status -short | tail -n +2
        echo
    else
        print_warning "Nomad is not running."
        return
    fi
    
    read -p "Service name or number to stop: " service_input
    
    if [ -z "$service_input" ]; then
        print_warning "No service specified."
        return
    fi
    
    local service_to_stop=""
    
    # Check if input is a number
    if [[ "$service_input" =~ ^[0-9]+$ ]]; then
        # It's a number, get service by number
        if [ "$service_input" -ge 1 ] && [ "$service_input" -le 26 ]; then
            local selected_service=$(get_service_key "$service_input")
            if [ -n "$selected_service" ]; then
                # Convert service key to job name
                case $selected_service in
                    "mysql") service_to_stop="mysql-server" ;;
                    "postgresql") service_to_stop="postgresql-server" ;;
                    "mongodb") service_to_stop="mongodb-server" ;;
                    "redis") service_to_stop="redis-server" ;;
                    "vault") service_to_stop="vault-server" ;;
                    "jenkins") service_to_stop="jenkins-server" ;;
                    "rabbitmq") service_to_stop="rabbitmq-server" ;;
                    "mattermost") service_to_stop="mattermost-server" ;;
                    "keycloak") service_to_stop="keycloak-server" ;;
                    "prometheus") service_to_stop="prometheus-server" ;;
                    "grafana") service_to_stop="grafana-server" ;;
                    "loki") service_to_stop="loki-server" ;;
                    "sonarqube") service_to_stop="sonarqube-server" ;;
                    "minio") service_to_stop="minio-server" ;;
                    "java") service_to_stop="java-server" ;;
                    "nodejs") service_to_stop="nodejs-server" ;;
                    "php") service_to_stop="php-server" ;;
                    "nexus") service_to_stop="nexus-server" ;;
                    "artifactory") service_to_stop="artifactory-server" ;;
                    "zookeeper") service_to_stop="zookeeper-server" ;;
                    "kafka") service_to_stop="kafka-server" ;;
                    "traefik") service_to_stop="traefik" ;;
                    "traefik-https") service_to_stop="traefik-https" ;;
                    "node-exporter") service_to_stop="node-exporter" ;;
                    "cadvisor") service_to_stop="cadvisor" ;;
                    "promtail") service_to_stop="promtail" ;;
                    *) service_to_stop="$selected_service" ;;
                esac
            else
                print_error "Invalid service number: $service_input"
                return
            fi
        else
            print_error "Invalid service number: $service_input (must be 1-26)"
            return
        fi
    else
        # It's a name, use it directly or convert if it's a service key
        local service_name=$(get_service_name "$service_input")
        if [ "$service_name" != "Unknown Service" ]; then
            # Convert service key to job name
            case $service_input in
                "mysql") service_to_stop="mysql-server" ;;
                "postgresql") service_to_stop="postgresql-server" ;;
                "mongodb") service_to_stop="mongodb-server" ;;
                "redis") service_to_stop="redis-server" ;;
                "vault") service_to_stop="vault-server" ;;
                "jenkins") service_to_stop="jenkins-server" ;;
                "rabbitmq") service_to_stop="rabbitmq-server" ;;
                "mattermost") service_to_stop="mattermost-server" ;;
                "keycloak") service_to_stop="keycloak-server" ;;
                "prometheus") service_to_stop="prometheus-server" ;;
                "grafana") service_to_stop="grafana-server" ;;
                "loki") service_to_stop="loki-server" ;;
                "sonarqube") service_to_stop="sonarqube-server" ;;
                "minio") service_to_stop="minio-server" ;;
                "java") service_to_stop="java-server" ;;
                "nodejs") service_to_stop="nodejs-server" ;;
                "php") service_to_stop="php-server" ;;
                "nexus") service_to_stop="nexus-server" ;;
                "artifactory") service_to_stop="artifactory-server" ;;
                "zookeeper") service_to_stop="zookeeper-server" ;;
                "kafka") service_to_stop="kafka-server" ;;
                "traefik") service_to_stop="traefik" ;;
                "traefik-https") service_to_stop="traefik-https" ;;
                "node-exporter") service_to_stop="node-exporter" ;;
                "cadvisor") service_to_stop="cadvisor" ;;
                "promtail") service_to_stop="promtail" ;;
                *) service_to_stop="$service_input" ;;
            esac
        else
            # Assume it's a direct job name
            service_to_stop="$service_input"
        fi
    fi
    
    # Confirm before stopping
    print_warning "Are you sure you want to stop '$service_to_stop'? (y/N)"
    read -p "Confirm: " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        print_status "Stopping service: $service_to_stop..."
        if nomad job stop "$service_to_stop"; then
            print_status "Service '$service_to_stop' stopped successfully!"
        else
            print_error "Failed to stop service '$service_to_stop' or service not found"
        fi
    else
        print_status "Operation cancelled."
    fi
}

# Function to deploy custom application
deploy_custom_application() {
    print_header "================== Deploy Custom Application =================="
    echo "Please provide the following information for your application:"
    
    read -p "Application name: " app_name
    read -p "Docker image (e.g., nginx:latest): " docker_image
    read -p "Port to expose (default 80): " app_port
    app_port=${app_port:-80}
    
    # Ensure Nomad is running
    ensure_nomad_running
    
    # Create custom job file
    local custom_job="$NOMAD_JOBS_DIR/custom-${app_name}.nomad"
    
    cat > "$custom_job" << EOF
job "custom-${app_name}" {
  datacenters = ["dc1"]
  type        = "service"

  group "app" {
    count = 1

    network {
      port "http" {
        static = ${app_port}
      }
    }

    task "${app_name}" {
      driver = "docker"

      config {
        image = "${docker_image}"
        ports = ["http"]
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "${app_name}"
        port = "http"

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
EOF

    print_status "Deploying custom application: $app_name..."
    if nomad job run "$custom_job"; then
        print_status "Custom application '$app_name' deployed successfully!"
        print_status "Application will be available at: http://localhost:$app_port"
    else
        print_error "Failed to deploy custom application"
    fi
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    
    # Check if Nomad is running before trying to stop jobs
    if nomad node status &> /dev/null; then
        # Stop all jobs
        print_status "Stopping all Nomad jobs..."
        for job in $(nomad job status -short | tail -n +2 | awk '{print $1}'); do
            nomad job stop "$job" || true
        done
    fi
    
    # Stop Nomad server
    stop_nomad_server
    
    # Stop Consul server
    stop_consul_server
}

# Main menu loop
main_menu() {
    while true; do
        echo
        print_header "================== Nomad Environment Manager =================="
        show_service_menu
        
        read -p "Select an option: " choice
        
        case $choice in
            0)
                print_status "Exiting..."
                cleanup
                exit 0
                ;;
            [1-9]|1[0-9]|2[0-6])
                # Get service key by number
                local selected_service=$(get_service_key "$choice")
                if [ -n "$selected_service" ]; then
                    deploy_service "$selected_service"
                    show_deployed_jobs
                else
                    print_error "Invalid selection"
                fi
                ;;
            27)
                deploy_custom_application
                show_deployed_jobs
                ;;
            28)
                deploy_multiple_services
                ;;
            29)
                show_deployed_jobs
                ;;
            30)
                stop_specific_service
                ;;
            31)
                print_warning "This will stop ALL running services. Are you sure? (y/N)"
                read -p "Confirm: " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    print_status "Stopping all services..."
                    if nomad node status &> /dev/null; then
                        for job in $(nomad job status -short | tail -n +2 | awk '{print $1}'); do
                            print_status "Stopping job: $job"
                            nomad job stop "$job" || true
                        done
                        print_status "All services stopped."
                    else
                        print_warning "Nomad is not running."
                    fi
                else
                    print_status "Operation cancelled."
                fi
                ;;
            *)
                print_error "Invalid option. Please try again."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Signal handlers
trap cleanup EXIT
trap cleanup SIGINT
trap cleanup SIGTERM

# Main execution
main() {
    print_header "🚀 Nomad Environment Manager"
    print_status "Welcome! Choose services to deploy in your development environment."
    echo
    
    # Load secrets before showing menu
    load_secrets
    echo
    
    # Show main menu immediately
    main_menu
}

# Run main function
main "$@"
