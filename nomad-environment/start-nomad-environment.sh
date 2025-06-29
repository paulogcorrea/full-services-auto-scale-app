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

# Available services
declare -A SERVICES=(
    ["php"]="PHP Server"
    ["mysql"]="MySQL Database Server"
    ["postgresql"]="PostgreSQL Database Server"
    ["vault"]="HashiCorp Vault"
    ["nexus"]="Sonatype Nexus Repository"
    ["artifactory"]="JFrog Artifactory"
    ["java"]="Java Application Server"
    ["rabbitmq"]="RabbitMQ Message Broker"
    ["jenkins"]="Jenkins CI/CD Server"
    ["nodejs"]="Node.js Backend API"
    ["mattermost"]="Mattermost Collaboration Tool"
)

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

# Function to check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Function to start Nomad server
start_nomad_server() {
    print_status "Starting Nomad server..."
    
    # Create data directory
    mkdir -p "$NOMAD_DATA_DIR"
    
    # Start Nomad in development mode (background)
    nohup nomad agent -dev \
        -bind=127.0.0.1 \
        -data-dir="$NOMAD_DATA_DIR" \
        -node=nomad-dev \
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
    print_header "================== Available Services =================="
    echo
    local i=1
    for key in "${!SERVICES[@]}"; do
        echo "$i) ${SERVICES[$key]} ($key)"
        ((i++))
    done
    echo "$i) Deploy Custom Application"
    echo "0) Exit"
    echo
}

# Function to deploy a service
deploy_service() {
    local service_key=$1
    local job_file="$NOMAD_JOBS_DIR/${service_key}.nomad"
    
    if [ -f "$job_file" ]; then
        print_status "Deploying ${SERVICES[$service_key]}..."
        if nomad job run "$job_file"; then
            print_status "${SERVICES[$service_key]} deployed successfully!"
        else
            print_error "Failed to deploy ${SERVICES[$service_key]}"
        fi
    else
        print_error "Job file not found: $job_file"
    fi
}

# Function to show deployed jobs
show_deployed_jobs() {
    print_header "================== Deployed Jobs =================="
    nomad job status
    echo
}

# Function to deploy custom application
deploy_custom_application() {
    print_header "================== Deploy Custom Application =================="
    echo "Please provide the following information for your application:"
    
    read -p "Application name: " app_name
    read -p "Docker image (e.g., nginx:latest): " docker_image
    read -p "Port to expose (default 80): " app_port
    app_port=${app_port:-80}
    
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
    
    # Stop all jobs
    print_status "Stopping all Nomad jobs..."
    for job in $(nomad job status -short | tail -n +2 | awk '{print $1}'); do
        nomad job stop "$job" || true
    done
    
    # Stop Nomad server
    stop_nomad_server
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
            [1-9]|1[01])
                # Get service key by index
                local service_keys=($(printf '%s\n' "${!SERVICES[@]}" | sort))
                local selected_service=${service_keys[$((choice-1))]}
                if [ -n "$selected_service" ]; then
                    deploy_service "$selected_service"
                    show_deployed_jobs
                else
                    print_error "Invalid selection"
                fi
                ;;
            12)
                deploy_custom_application
                show_deployed_jobs
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
    print_header "Starting Nomad Environment Manager"
    
    # Pre-flight checks
    check_nomad_installation
    check_docker
    
    # Start Nomad server
    start_nomad_server
    
    # Show main menu
    main_menu
}

# Run main function
main "$@"
