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

# Function to get service endpoints
get_service_endpoints() {
    local service_key=$1
    case $service_key in
        "prometheus")
            echo "🌐 Prometheus UI: http://localhost:9090"
            echo "📊 Targets: http://localhost:9090/targets"
            echo "📈 Graph: http://localhost:9090/graph"
            ;;
        "grafana")
            echo "🌐 Grafana Dashboard: http://localhost:3001"
            echo "👤 Login: admin / [vault password]"
            echo "📊 Default Dashboard: http://localhost:3001/dashboards"
            ;;
        "loki")
            echo "🌐 Loki API: http://localhost:3100"
            echo "📋 Labels: http://localhost:3100/loki/api/v1/labels"
            echo "🔍 Query: http://localhost:3100/loki/api/v1/query"
            ;;
        "node-exporter")
            echo "🌐 Node Exporter: http://localhost:9100"
            echo "📊 Metrics: http://localhost:9100/metrics"
            ;;
        "cadvisor")
            echo "🌐 cAdvisor UI: http://localhost:8083"
            echo "📊 Container Stats: http://localhost:8083/containers/"
            echo "📈 Metrics: http://localhost:8083/metrics"
            ;;
        "mysql")
            echo "🗄️ MySQL Database: localhost:3306"
            echo "👤 Root User: root / [vault password]"
            echo "🗃️ Test Database: testdb (user: testuser / pass: testpass)"
            echo "📱 Connection: mysql -h localhost -P 3306 -u root -p"
            ;;
        "postgresql")
            echo "🗄️ PostgreSQL Database: localhost:5432"
            echo "👤 User: [vault username] / [vault password]"
            echo "🗃️ Database: testdb"
            echo "📱 Connection: psql -h localhost -p 5432 -U [username] -d testdb"
            ;;
        "mongodb")
            echo "🗄️ MongoDB Database: localhost:27017"
            echo "👤 User: [vault username] / [vault password]"
            echo "🗃️ Database: testdb"
            echo "📱 Connection: mongosh mongodb://[username]:[password]@localhost:27017/testdb"
            ;;
        "redis")
            echo "⚡ Redis Server: localhost:6379"
            echo "📱 Connection: redis-cli -h localhost -p 6379"
            echo "🔑 Password: [vault password] (if auth enabled)"
            ;;
        "zookeeper")
            echo "🐘 ZooKeeper: localhost:2181 (client)"
            echo "📊 Admin: localhost:8080"
            echo "🔧 JMX: localhost:7071"
            echo "📱 CLI: zkCli.sh -server localhost:2181"
            ;;
        "kafka")
            echo "📨 Kafka Broker: localhost:9092"
            echo "🔧 JMX: localhost:7072"
            echo "📱 Producer: kafka-console-producer --broker-list localhost:9092 --topic test"
            echo "📱 Consumer: kafka-console-consumer --bootstrap-server localhost:9092 --topic test"
            ;;
        "rabbitmq")
            echo "🐰 RabbitMQ AMQP: localhost:5672"
            echo "🌐 Management UI: http://localhost:15672"
            echo "👤 Login: [vault username] / [vault password]"
            echo "📱 Connection: amqp://[username]:[password]@localhost:5672/"
            ;;
        "php")
            echo "🌐 PHP Server: http://localhost:8080"
            echo "📂 Document Root: /var/www/html"
            echo "ℹ️ PHP Info: http://localhost:8080/phpinfo.php"
            ;;
        "nodejs")
            echo "🌐 Node.js API: http://localhost:3000"
            echo "📊 Health Check: http://localhost:3000/health"
            echo "📈 Metrics: http://localhost:3000/metrics"
            ;;
        "java")
            echo "🌐 Java Application: http://localhost:8090"
            echo "📊 Health Check: http://localhost:8090/health"
            echo "📱 API Docs: http://localhost:8090/swagger-ui.html"
            ;;
        "jenkins")
            echo "🌐 Jenkins CI/CD: http://localhost:8088"
            echo "👤 Login: [vault username] / [vault password]"
            echo "🔧 Agent Port: localhost:50000"
            echo "📱 CLI: java -jar jenkins-cli.jar -s http://localhost:8088/"
            ;;
        "sonarqube")
            echo "🌐 SonarQube: http://localhost:9002"
            echo "👤 Default Login: admin / admin (change on first login)"
            echo "📊 Projects: http://localhost:9002/projects"
            ;;
        "nexus")
            echo "🌐 Nexus Repository: http://localhost:8081"
            echo "👤 Login: admin / [vault password]"
            echo "📦 Maven Central: http://localhost:8081/repository/maven-central/"
            echo "📤 Uploads: http://localhost:8081/repository/maven-releases/"
            ;;
        "artifactory")
            echo "🌐 JFrog Artifactory: http://localhost:8082"
            echo "👤 Login: [vault username] / [vault password]"
            echo "📦 Repositories: http://localhost:8082/ui/repos/tree/General"
            ;;
        "vault")
            echo "🌐 Vault UI: http://localhost:8200"
            echo "🔑 Root Token: myroot (dev mode)"
            echo "📱 CLI: vault auth -method=userpass username=admin"
            echo "📋 API: http://localhost:8200/v1/sys/health"
            ;;
        "keycloak")
            echo "🌐 Keycloak Admin: http://localhost:8070"
            echo "👤 Admin Login: [vault username] / [vault password]"
            echo "🏛️ Realms: http://localhost:8070/admin/master/console/"
            ;;
        "minio")
            echo "🌐 MinIO Console: http://localhost:9001"
            echo "📦 S3 API: http://localhost:9000"
            echo "👤 Login: [vault username] / [vault password]"
            echo "🪣 Buckets: uploads, backups, images, documents, logs"
            ;;
        "mattermost")
            echo "🌐 Mattermost: http://localhost:8065"
            echo "👤 Setup: Create admin account on first visit"
            echo "💬 Team: http://localhost:8065/[team-name]"
            ;;
        "traefik")
            echo "🌐 Traefik Dashboard: http://localhost:8079"
            echo "🔀 HTTP Proxy: http://localhost:80"
            echo "🔒 HTTPS Proxy: https://localhost:443"
            echo "📊 API: http://localhost:8079/api/rawdata"
            ;;
        "traefik-https")
            echo "🌐 Traefik Dashboard: http://localhost:8079"
            echo "🔀 HTTP Proxy: http://localhost:80"
            echo "🔒 HTTPS Proxy: https://localhost:443"
            echo "📊 API: http://localhost:8079/api/rawdata"
            echo "🔐 Certificate Management: Auto HTTPS with Let's Encrypt"
            ;;
        "promtail")
            echo "📋 Promtail: localhost:9080 (metrics)"
            echo "📤 Log Shipping: Sends logs to Loki at localhost:3100"
            echo "📊 Metrics: http://localhost:9080/metrics"
            ;;
        *)
            echo "ℹ️ Service endpoints not configured for: $service_key"
            ;;
    esac
}

# Function to display service info after successful deployment
show_service_info() {
    local service_key=$1
    local service_name=$(get_service_name "$service_key")
    
    echo
    print_header "🎉 $service_name Deployed Successfully!"
    echo
    
    # Show endpoints
    print_status "📍 Service Endpoints:"
    get_service_endpoints "$service_key"
    echo
    
    # Show Traefik proxy info if Traefik is available
    if nomad job status traefik >/dev/null 2>&1 || nomad job status traefik-https >/dev/null 2>&1; then
        case $service_key in
            "grafana"|"prometheus"|"jenkins"|"rabbitmq"|"mattermost"|"keycloak"|"vault"|"nexus"|"artifactory"|"cadvisor"|"java"|"minio"|"sonarqube"|"php"|"nodejs")
                print_status "🌍 Traefik Proxy URLs (if Traefik is running):"
                case $service_key in
                    "grafana") echo "   https://grafana.localhost (via Traefik)" ;;
                    "prometheus") echo "   https://prometheus.localhost (via Traefik)" ;;
                    "jenkins") echo "   https://jenkins.localhost (via Traefik)" ;;
                    "rabbitmq") echo "   https://rabbitmq.localhost (via Traefik)" ;;
                    "mattermost") echo "   https://mattermost.localhost (via Traefik)" ;;
                    "keycloak") echo "   https://keycloak.localhost (via Traefik)" ;;
                    "vault") echo "   https://vault.localhost (via Traefik)" ;;
                    "nexus") echo "   https://nexus.localhost (via Traefik)" ;;
                    "artifactory") echo "   https://artifactory.localhost (via Traefik)" ;;
                    "cadvisor") echo "   https://cadvisor.localhost (via Traefik)" ;;
                    "java") echo "   https://java.localhost (via Traefik)" ;;
                    "minio") echo "   https://minio.localhost (via Traefik)" ;;
                    "sonarqube") echo "   https://sonarqube.localhost (via Traefik)" ;;
                    "php") echo "   https://php.localhost (via Traefik)" ;;
                    "nodejs") echo "   https://api.localhost (via Traefik)" ;;
                esac
                echo
                ;;
        esac
    fi
    
    # Show additional tips
    case $service_key in
        "mysql"|"postgresql"|"mongodb"|"redis")
            print_status "💡 Database Tips:"
            echo "   • Use these services as backends for your applications"
            echo "   • Data is persisted in Docker volumes"
            echo "   • Check Nomad UI for detailed service status: http://localhost:4646"
            ;;
        "prometheus")
            print_status "💡 Monitoring Tips:"
            echo "   • Prometheus scrapes metrics from all deployed services"
            echo "   • Configure Grafana to use Prometheus as data source"
            echo "   • Check service discovery: http://localhost:9090/targets"
            ;;
        "grafana")
            print_status "💡 Visualization Tips:"
            echo "   • Prometheus datasource is pre-configured"
            echo "   • Import dashboards from grafana.com"
            echo "   • Create custom dashboards for your applications"
            ;;
        "traefik"|"traefik-https")
            print_status "💡 Proxy Tips:"
            echo "   • Traefik automatically discovers services"
            echo "   • Add .localhost domains to /etc/hosts for local development"
            echo "   • Use labels in Nomad jobs for custom routing"
            ;;
    esac
    
    echo
    print_status "🔗 Additional Resources:"
    echo "   • Nomad UI: http://localhost:4646"
    echo "   • Consul UI: http://localhost:8500"
    echo "   • Service logs: nomad alloc logs [allocation-id]"
    echo
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
                    show_service_info "$selected_service"
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
