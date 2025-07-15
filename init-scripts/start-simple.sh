#!/bin/bash

# Simplified Startup Script
# This script starts only PostgreSQL, Backend, and Frontend (no Consul/Nomad)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration - Updated for new folder structure
BASE_DIR="$(pwd)"
BACKEND_DIR="$BASE_DIR/backend"
FRONTEND_DIR="$BASE_DIR/frontend"
LOG_DIR="$BASE_DIR/logs"
POSTGRES_SETUP_SCRIPT="$BASE_DIR/init-scripts/setup-postgresql.sh"

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
    print_header "SIMPLE PLATFORM STARTUP"
    echo -e "${PURPLE}Starting PostgreSQL → Backend → Frontend${NC}"
    echo ""
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    # Check required commands
    REQUIRED_COMMANDS=(docker go node npm)
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command_exists "$cmd"; then
            print_error "$cmd is not installed or not in PATH"
            exit 1
        fi
    done
    
    print_success "All prerequisites are installed"
    
    # 1. Start PostgreSQL Docker container
    print_header "1. STARTING POSTGRESQL (DOCKER)"
    
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
        if docker exec nomad-services-postgres pg_isready -U nomad_services >/dev/null 2>&1; then
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
    
    # 2. Start Backend API
    print_header "2. STARTING BACKEND API"
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
    
    # 3. Start Frontend
    print_header "3. STARTING FRONTEND"
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
        
        # Wait for Angular dev server to start
        print_status "Waiting for Angular dev server to start..."
        local max_attempts=30
        local attempt=1
        local compilation_started=false
        
        while [ $attempt -le $max_attempts ]; do
            # Check if compilation has started by looking for webpack output
            if [ "$compilation_started" = false ] && grep -q "webpack" "$LOG_DIR/frontend.log" 2>/dev/null; then
                print_status "Angular compilation started..."
                compilation_started=true
            fi
            
            # Check if Angular dev server is responding
            if curl -s -f "http://localhost:4200" > /dev/null 2>&1; then
                print_success "Frontend is ready!"
                break
            fi
            
            # Check for compilation errors
            if grep -q "ERROR" "$LOG_DIR/frontend.log" 2>/dev/null; then
                print_warning "Compilation errors detected, but continuing..."
            fi
            
            # Check if server is bound but not ready (typical Angular behavior)
            if curl -s "http://localhost:4200" 2>/dev/null | grep -q "Cannot GET" 2>/dev/null; then
                print_status "Angular server is bound but still compiling..."
            fi
            
            if [ $attempt -eq $max_attempts ]; then
                print_warning "Angular dev server is taking longer than expected. Check logs at $LOG_DIR/frontend.log"
                print_warning "The server might still be starting. You can check http://localhost:4200 manually."
                break
            fi
            
            # Dynamic sleep based on compilation state
            if [ "$compilation_started" = true ]; then
                echo -n "."
                sleep 2  # Faster polling once compilation started
            else
                echo -n "o"
                sleep 3  # Slower polling initially
            fi
            
            attempt=$((attempt + 1))
        done
    else
        print_success "Frontend is already running"
    fi
    
    # Display status
    print_header "PLATFORM STATUS"
    echo -e "${PURPLE}🎉 Simple Platform is now running!${NC}"
    echo ""
    print_status "Services:"
    print_status "  🐘 PostgreSQL:     localhost:5432 (Docker)"
    print_status "  🔧 Backend API:    http://localhost:8080"
    print_status "  🌐 Frontend App:   http://localhost:4200"
    echo ""
    print_status "Quick Links:"
    print_status "  Health Check:      http://localhost:8080/health"
    print_status "  API Base:          http://localhost:8080/api/v1"
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
    echo "Simple Platform Startup Script"
    echo ""
    echo "Usage: $0"
    echo ""
    echo "This script will start in order:"
    echo "  1. PostgreSQL (Docker container on port 5432)"
    echo "  2. Backend API (Go application on port 8080)"
    echo "  3. Frontend (Angular application on port 4200)"
    echo ""
    echo "Prerequisites:"
    echo "  - Docker (for PostgreSQL)"
    echo "  - Go (for backend)"
    echo "  - Node.js and npm (for frontend)"
    echo ""
    echo "Logs will be saved to the logs/ directory"
    echo "Press Ctrl+C to stop all services"
    exit 0
fi

# Run main function
main "$@"
