#!/bin/bash

# Nomad Services Full Platform Startup Script
# This script starts the complete platform: PostgreSQL (Docker), Consul, Nomad, Backend API, and Frontend

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration - Updated for new folder structure
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
NOMAD_DIR="$BASE_DIR/nomad-environment"
BACKEND_DIR="$BASE_DIR/backend"
FRONTEND_DIR="$BASE_DIR/frontend"
LOG_DIR="$NOMAD_DIR/logs"
POSTGRES_SETUP_SCRIPT="$BASE_DIR/init-scripts/setup-postgresql.sh"
POSTGRES_ENV_FILE="$BASE_DIR/.env.postgres"

# Create logs directory
mkdir -p "$LOG_DIR"

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
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a port is in use
port_in_use() {
    lsof -i :"$1" >/dev/null 2>&1
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1

    print_status "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" >/dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_error "$service_name failed to start after $max_attempts attempts"
            return 1
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
}

# Function to wait for Docker container to be healthy
wait_for_docker_container() {
    local container_name=$1
    local max_attempts=30
    local attempt=1

    print_status "Waiting for Docker container $container_name to be healthy..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name.*healthy\|$container_name.*Up"; then
            print_success "Container $container_name is healthy!"
            return 0
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_error "Container $container_name failed to become healthy after $max_attempts attempts"
            return 1
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
}

# Function to cleanup processes on exit
cleanup() {
    print_warning "Stopping services..."
    
    # Stop frontend
    if [ ! -z "$FRONTEND_PID" ] && kill -0 "$FRONTEND_PID" 2>/dev/null; then
        print_status "Stopping frontend..."
        kill "$FRONTEND_PID" 2>/dev/null || true
        wait "$FRONTEND_PID" 2>/dev/null || true
    fi
    
    # Stop backend
    if [ ! -z "$BACKEND_PID" ] && kill -0 "$BACKEND_PID" 2>/dev/null; then
        print_status "Stopping backend..."
        kill "$BACKEND_PID" 2>/dev/null || true
        wait "$BACKEND_PID" 2>/dev/null || true
    fi
    
    # Stop Nomad
    if [ -f "$NOMAD_DIR/nomad.pid" ]; then
        NOMAD_PID=$(cat "$NOMAD_DIR/nomad.pid")
        if kill -0 "$NOMAD_PID" 2>/dev/null; then
            print_status "Stopping Nomad..."
            kill "$NOMAD_PID" 2>/dev/null || true
            wait "$NOMAD_PID" 2>/dev/null || true
        fi
        rm -f "$NOMAD_DIR/nomad.pid"
    fi
    
    # Stop Consul
    if [ -f "$NOMAD_DIR/consul.pid" ]; then
        CONSUL_PID=$(cat "$NOMAD_DIR/consul.pid")
        if kill -0 "$CONSUL_PID" 2>/dev/null; then
            print_status "Stopping Consul..."
            kill "$CONSUL_PID" 2>/dev/null || true
            wait "$CONSUL_PID" 2>/dev/null || true
        fi
        rm -f "$NOMAD_DIR/consul.pid"
    fi
    
    # Stop PostgreSQL Docker container
    if docker ps -q -f name=nomad-services-postgres >/dev/null 2>&1; then
        print_status "Stopping PostgreSQL container..."
        docker stop nomad-services-postgres >/dev/null 2>&1 || true
    fi
    
    print_success "Cleanup completed"
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Main startup function
main() {
    print_header "NOMAD SERVICES FULL PLATFORM STARTUP"
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    # Check required commands
    REQUIRED_COMMANDS=(docker docker-compose nomad consul go node npm)
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command_exists "$cmd"; then
            print_error "$cmd is not installed or not in PATH"
            exit 1
        fi
    done
    
    print_success "All prerequisites are installed"
    
    # Start PostgreSQL Docker container
    print_header "STARTING POSTGRESQL (DOCKER)"
    
    # Check if PostgreSQL setup script exists
    if [ ! -f "$POSTGRES_SETUP_SCRIPT" ]; then
        print_error "PostgreSQL setup script not found at $POSTGRES_SETUP_SCRIPT"
        exit 1
    fi
    
    # Start PostgreSQL using our setup script
    print_status "Starting PostgreSQL container..."
    cd "$BASE_DIR"
    
    # Check if container exists, if not create it
    if ! docker ps -a --format '{{.Names}}' | grep -q "^nomad-services-postgres$"; then
        print_status "PostgreSQL container doesn't exist, creating it..."
        if ! "$POSTGRES_SETUP_SCRIPT"; then
            print_error "Failed to create PostgreSQL container"
            exit 1
        fi
    else
        # Container exists, just start it
        if ! "$POSTGRES_SETUP_SCRIPT" start; then
            print_error "Failed to start PostgreSQL container"
            exit 1
        fi
    fi
    
    # Wait for PostgreSQL to be healthy
    wait_for_docker_container "nomad-services-postgres"
    
    # Verify PostgreSQL is accessible
    print_status "Verifying PostgreSQL connection..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec nomad-services-postgres pg_isready -U nomad_services > /dev/null 2>&1; then
            print_success "PostgreSQL is ready and accessible"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_error "PostgreSQL failed to become ready after $max_attempts attempts"
            exit 1
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    # Start Consul
    print_header "STARTING CONSUL"
    if ! port_in_use 8500; then
        print_status "Starting Consul..."
        cd "$NOMAD_DIR"
        consul agent -dev -log-level=INFO > "$LOG_DIR/consul.log" 2>&1 &
        CONSUL_PID=$!
        echo $CONSUL_PID > "$NOMAD_DIR/consul.pid"
        
        wait_for_service "http://localhost:8500/v1/status/leader" "Consul"
    else
        print_success "Consul is already running"
    fi
    
    # Start Nomad
    print_header "STARTING NOMAD"
    if ! port_in_use 4646; then
        print_status "Starting Nomad..."
        cd "$NOMAD_DIR"
        
        # Check if Nomad config exists
        if [ ! -f "configs/nomad-server.hcl" ]; then
            print_error "Nomad config file not found at configs/nomad-server.hcl"
            exit 1
        fi
        
        nomad agent -config=configs/nomad-server.hcl > "$LOG_DIR/nomad.log" 2>&1 &
        NOMAD_PID=$!
        echo $NOMAD_PID > "$NOMAD_DIR/nomad.pid"
        
        wait_for_service "http://localhost:4646/v1/status/leader" "Nomad"
    else
        print_success "Nomad is already running"
    fi
    
    # Start Backend API
    print_header "STARTING BACKEND API"
    if ! port_in_use 8080; then
        cd "$BACKEND_DIR"
        
        # Check if .env exists
        if [ ! -f ".env" ]; then
            print_error ".env file not found in backend directory"
            exit 1
        fi
        
        print_status "Installing Go dependencies..."
        go mod tidy
        
        print_status "Starting Go backend..."
        go run main.go > "$LOG_DIR/backend.log" 2>&1 &
        BACKEND_PID=$!
        
        wait_for_service "http://localhost:8080/health" "Backend API"
    else
        print_success "Backend API is already running"
    fi
    
    # Start Frontend
    print_header "STARTING FRONTEND"
    if ! port_in_use 4200; then
        cd "$FRONTEND_DIR"
        
        # Check if package.json exists
        if [ ! -f "package.json" ]; then
            print_error "package.json not found in frontend directory"
            exit 1
        fi
        
        # Check if node_modules exists
        if [ ! -d "node_modules" ]; then
            print_status "Installing npm dependencies..."
            npm install --legacy-peer-deps
        fi
        
        print_status "Starting Angular frontend..."
        npm start > "$LOG_DIR/frontend.log" 2>&1 &
        FRONTEND_PID=$!
        
        wait_for_service "http://localhost:4200" "Frontend"
    else
        print_success "Frontend is already running"
    fi
    
    # Display status
    print_header "PLATFORM STATUS"
    echo -e "${PURPLE}🎉 Nomad Services Platform is now running!${NC}"
    echo ""
    print_status "Services:"
    print_status "  🐘 PostgreSQL:     localhost:5432 (Docker)"
    print_status "  📊 Consul UI:      http://localhost:8500"
    print_status "  🚀 Nomad UI:       http://localhost:4646"
    print_status "  🔧 Backend API:    http://localhost:8080"
    print_status "  🌐 Frontend App:   http://localhost:4200"
    echo ""
    print_status "Quick Links:"
    print_status "  Health Check:      http://localhost:8080/health"
    print_status "  API Base:          http://localhost:8080/api/v1"
    print_status "  Consul Services:   http://localhost:8500/ui/dc1/services"
    print_status "  Nomad Jobs:        http://localhost:4646/ui/jobs"
    echo ""
    print_status "Database Info:"
    print_status "  Host:              localhost:5432"
    print_status "  Database:          nomad_services"
    print_status "  Username:          nomad_services"
    print_status "  Password:          secure_password"
    echo ""
    print_status "Logs are available in: $LOG_DIR"
    echo ""
    print_warning "Press Ctrl+C to stop all services"
    
    # Keep script running and monitor services
    while true; do
        sleep 10
        
        # Check if services are still running
        if [ ! -z "$BACKEND_PID" ] && ! kill -0 "$BACKEND_PID" 2>/dev/null; then
            print_error "Backend API has stopped unexpectedly"
            break
        fi
        
        if [ ! -z "$FRONTEND_PID" ] && ! kill -0 "$FRONTEND_PID" 2>/dev/null; then
            print_error "Frontend has stopped unexpectedly"
            break
        fi
        
        # Check if PostgreSQL container is still running
        if ! docker ps -q -f name=nomad-services-postgres >/dev/null 2>&1; then
            print_error "PostgreSQL container has stopped unexpectedly"
            break
        fi
    done
}

# Show usage if help requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Nomad Services Full Platform Startup Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --dev          Start in development mode (default)"
    echo "  --prod         Start in production mode"
    echo ""
    echo "This script will start:"
    echo "  - PostgreSQL (Docker container on port 5432)"
    echo "  - Consul (port 8500)"
    echo "  - Nomad (port 4646)"
    echo "  - Backend API (port 8080)"
    echo "  - Frontend (port 4200)"
    echo ""
    echo "Prerequisites:"
    echo "  - Docker and Docker Compose"
    echo "  - Nomad binary"
    echo "  - Consul binary"
    echo "  - Go (for backend)"
    echo "  - Node.js and npm (for frontend)"
    echo ""
    echo "Logs will be saved to the nomad-environment/logs/ directory"
    echo "Press Ctrl+C to stop all services"
    exit 0
fi

# Run main function
main "$@"
