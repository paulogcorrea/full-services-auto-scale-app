#!/bin/bash

# Simple Platform Stop Script
# This script stops PostgreSQL, Backend, and Frontend

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to stop processes by port
stop_process_by_port() {
    local port=$1
    local service_name=$2
    
    local pid=$(lsof -ti :$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        print_status "Stopping $service_name on port $port (PID: $pid)..."
        kill "$pid" 2>/dev/null || true
        
        # Wait for process to stop
        local attempts=0
        while [ $attempts -lt 10 ] && kill -0 "$pid" 2>/dev/null; do
            sleep 1
            attempts=$((attempts + 1))
        done
        
        if kill -0 "$pid" 2>/dev/null; then
            print_warning "Force killing $service_name..."
            kill -9 "$pid" 2>/dev/null || true
        fi
        
        print_status "$service_name stopped"
    else
        print_status "$service_name is not running"
    fi
}

main() {
    print_header "STOPPING SIMPLE PLATFORM"
    
    # Stop frontend (port 4200)
    print_status "Stopping Frontend..."
    stop_process_by_port 4200 "Frontend"
    
    # Stop backend (port 8080)
    print_status "Stopping Backend API..."
    stop_process_by_port 8080 "Backend API"
    
    # Stop PostgreSQL Docker container
    print_status "Stopping PostgreSQL container..."
    if docker ps -q -f name=nomad-services-postgres >/dev/null 2>&1; then
        docker stop nomad-services-postgres >/dev/null 2>&1 || true
        print_status "PostgreSQL container stopped"
    else
        print_status "PostgreSQL container is not running"
    fi
    
    print_header "SIMPLE PLATFORM STOPPED"
    print_status "✅ All services have been stopped"
}

# Show usage if help requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Simple Platform Stop Script"
    echo ""
    echo "Usage: $0"
    echo ""
    echo "This script will stop:"
    echo "  - Frontend (port 4200)"
    echo "  - Backend API (port 8080)"
    echo "  - PostgreSQL Docker container"
    echo ""
    exit 0
fi

# Run main function
main "$@"
