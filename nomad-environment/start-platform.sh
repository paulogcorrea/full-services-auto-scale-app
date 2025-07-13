#!/bin/bash

# Nomad Services Platform Startup Script
# This script starts the complete platform: Nomad, Consul, Backend API, and Frontend

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NOMAD_DIR="$(pwd)"
BACKEND_DIR="$NOMAD_DIR/backend"
FRONTEND_DIR="$NOMAD_DIR/frontend"
LOG_DIR="$NOMAD_DIR/logs"

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
            print_status "$service_name is ready!"
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

# Function to cleanup processes on exit
cleanup() {
    print_warning "Stopping services..."
    
    # Stop frontend
    if [ ! -z "$FRONTEND_PID" ] && kill -0 "$FRONTEND_PID" 2>/dev/null; then
        print_status "Stopping frontend..."
        kill "$FRONTEND_PID" 2>/dev/null || true
    fi
    
    # Stop backend
    if [ ! -z "$BACKEND_PID" ] && kill -0 "$BACKEND_PID" 2>/dev/null; then
        print_status "Stopping backend..."
        kill "$BACKEND_PID" 2>/dev/null || true
    fi
    
    # Stop Nomad
    if [ -f "$NOMAD_DIR/nomad.pid" ]; then
        NOMAD_PID=$(cat "$NOMAD_DIR/nomad.pid")
        if kill -0 "$NOMAD_PID" 2>/dev/null; then
            print_status "Stopping Nomad..."
            kill "$NOMAD_PID" 2>/dev/null || true
        fi
        rm -f "$NOMAD_DIR/nomad.pid"
    fi
    
    # Stop Consul
    if [ -f "$NOMAD_DIR/consul.pid" ]; then
        CONSUL_PID=$(cat "$NOMAD_DIR/consul.pid")
        if kill -0 "$CONSUL_PID" 2>/dev/null; then
            print_status "Stopping Consul..."
            kill "$CONSUL_PID" 2>/dev/null || true
        fi
        rm -f "$NOMAD_DIR/consul.pid"
    fi
    
    print_status "Cleanup completed"
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Main startup function
main() {
    print_header "NOMAD SERVICES PLATFORM STARTUP"
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    # Check required commands
    for cmd in nomad consul go node npm; do
        if ! command_exists "$cmd"; then
            print_error "$cmd is not installed or not in PATH"
            exit 1
        fi
    done
    
    print_status "All prerequisites are installed"
    
    # Check if ports are available
    print_status "Checking port availability..."
    
    REQUIRED_PORTS=(4646 8500 8080 4200 5432)
    for port in "${REQUIRED_PORTS[@]}"; do
        if port_in_use "$port"; then
            print_warning "Port $port is already in use"
        fi
    done
    
    # Start PostgreSQL if not running
    print_header "STARTING POSTGRESQL"
    if ! port_in_use 5432; then
        print_status "Starting PostgreSQL..."
        if command_exists brew; then
            brew services start postgresql@13 || brew services start postgresql
        elif command_exists systemctl; then
            sudo systemctl start postgresql
        else
            print_warning "Please start PostgreSQL manually on port 5432"
        fi
        sleep 3
    else
        print_status "PostgreSQL is already running"
    fi
    
    # Start Consul
    print_header "STARTING CONSUL"
    if ! port_in_use 8500; then
        print_status "Starting Consul..."
        consul agent -dev -log-level=INFO > "$LOG_DIR/consul.log" 2>&1 &
        CONSUL_PID=$!
        echo $CONSUL_PID > "$NOMAD_DIR/consul.pid"
        
        wait_for_service "http://localhost:8500/v1/status/leader" "Consul"
    else
        print_status "Consul is already running"
    fi
    
    # Start Nomad
    print_header "STARTING NOMAD"
    if ! port_in_use 4646; then
        print_status "Starting Nomad..."
        cd "$NOMAD_DIR"
        nomad agent -config=configs/nomad-server.hcl > "$LOG_DIR/nomad.log" 2>&1 &
        NOMAD_PID=$!
        echo $NOMAD_PID > "$NOMAD_DIR/nomad.pid"
        
        wait_for_service "http://localhost:4646/v1/status/leader" "Nomad"
    else
        print_status "Nomad is already running"
    fi
    
    # Setup database
    print_header "SETTING UP DATABASE"
    cd "$BACKEND_DIR"
    
    # Check if .env exists, if not copy from example
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            print_status "Creating .env file from template..."
            cp .env.example .env
            print_warning "Please update the .env file with your configuration"
        else
            print_error ".env.example file not found"
        fi
    fi
    
    # Create database if it doesn't exist
    print_status "Setting up database..."
    if command_exists psql; then
        psql -h localhost -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'nomad_services'" | grep -q 1 || \
        psql -h localhost -U postgres -c "CREATE DATABASE nomad_services;"
        print_status "Database setup completed"
    else
        print_warning "psql not found, please create the database manually"
    fi
    
    # Start Backend API
    print_header "STARTING BACKEND API"
    if ! port_in_use 8080; then
        print_status "Installing Go dependencies..."
        go mod tidy
        
        print_status "Starting Go backend..."
        go run main.go > "$LOG_DIR/backend.log" 2>&1 &
        BACKEND_PID=$!
        
        wait_for_service "http://localhost:8080/health" "Backend API"
    else
        print_status "Backend API is already running"
    fi
    
    # Start Frontend
    print_header "STARTING FRONTEND"
    if ! port_in_use 4200; then
        cd "$FRONTEND_DIR"
        
        # Check if node_modules exists
        if [ ! -d "node_modules" ]; then
            print_status "Installing npm dependencies..."
            npm install
        fi
        
        print_status "Starting Angular frontend..."
        npm start > "$LOG_DIR/frontend.log" 2>&1 &
        FRONTEND_PID=$!
        
        wait_for_service "http://localhost:4200" "Frontend"
    else
        print_status "Frontend is already running"
    fi
    
    # Display status
    print_header "PLATFORM STATUS"
    print_status "🎉 Nomad Services Platform is now running!"
    echo ""
    print_status "Services:"
    print_status "  📊 Consul UI:      http://localhost:8500"
    print_status "  🚀 Nomad UI:       http://localhost:4646"
    print_status "  🔧 Backend API:    http://localhost:8080"
    print_status "  🌐 Frontend App:   http://localhost:4200"
    echo ""
    print_status "API Endpoints:"
    print_status "  Health Check:      http://localhost:8080/health"
    print_status "  API Documentation: http://localhost:8080/api/v1"
    echo ""
    print_status "Logs are available in: $LOG_DIR"
    echo ""
    print_warning "Press Ctrl+C to stop all services"
    
    # Keep script running
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
    done
}

# Show usage if help requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Nomad Services Platform Startup Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --dev          Start in development mode"
    echo "  --prod         Start in production mode"
    echo ""
    echo "This script will start:"
    echo "  - PostgreSQL (if not running)"
    echo "  - Consul (port 8500)"
    echo "  - Nomad (port 4646)"
    echo "  - Backend API (port 8080)"
    echo "  - Frontend (port 4200)"
    echo ""
    echo "Logs will be saved to the logs/ directory"
    exit 0
fi

# Run main function
main "$@"
