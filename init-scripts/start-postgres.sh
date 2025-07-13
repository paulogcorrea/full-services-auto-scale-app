#!/bin/bash

# Quick PostgreSQL startup script for Nomad Services Backend API
# This script starts only the PostgreSQL database using Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if docker-compose is available
check_docker_compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker-compose"
    elif docker compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker compose"
    else
        print_error "Docker Compose is not available. Please install Docker Compose."
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Function to create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    mkdir -p ./data/postgresql
    mkdir -p ./backups/postgresql
    mkdir -p ./init-scripts
    print_success "Directories created"
}

# Function to start PostgreSQL
start_postgres() {
    print_status "Starting PostgreSQL database..."
    
    # Load environment variables
    if [ -f .env.postgres ]; then
        export $(cat .env.postgres | grep -v '^#' | xargs)
    fi
    
    # Start PostgreSQL using Docker Compose
    $DOCKER_COMPOSE_CMD -f docker-compose.postgres.yml up -d postgres
    
    print_success "PostgreSQL started"
}

# Function to start PostgreSQL with PgAdmin
start_postgres_with_admin() {
    print_status "Starting PostgreSQL database with PgAdmin..."
    
    # Load environment variables
    if [ -f .env.postgres ]; then
        export $(cat .env.postgres | grep -v '^#' | xargs)
    fi
    
    # Start PostgreSQL and PgAdmin using Docker Compose
    $DOCKER_COMPOSE_CMD -f docker-compose.postgres.yml --profile admin up -d
    
    print_success "PostgreSQL and PgAdmin started"
}

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    print_status "Waiting for PostgreSQL to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if $DOCKER_COMPOSE_CMD -f docker-compose.postgres.yml exec postgres pg_isready -U nomad_services >/dev/null 2>&1; then
            print_success "PostgreSQL is ready"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "PostgreSQL failed to start within ${max_attempts} attempts"
    return 1
}

# Function to stop PostgreSQL
stop_postgres() {
    print_status "Stopping PostgreSQL database..."
    $DOCKER_COMPOSE_CMD -f docker-compose.postgres.yml down
    print_success "PostgreSQL stopped"
}

# Function to show logs
show_logs() {
    print_status "Showing PostgreSQL logs..."
    $DOCKER_COMPOSE_CMD -f docker-compose.postgres.yml logs -f postgres
}

# Function to connect to database
connect_to_database() {
    print_status "Connecting to PostgreSQL database..."
    $DOCKER_COMPOSE_CMD -f docker-compose.postgres.yml exec postgres psql -U nomad_services -d nomad_services
}

# Function to show status
show_status() {
    print_status "PostgreSQL Status:"
    $DOCKER_COMPOSE_CMD -f docker-compose.postgres.yml ps
}

# Function to backup database
backup_database() {
    print_status "Creating database backup..."
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="./backups/postgresql/nomad_services_backup_${TIMESTAMP}.sql"
    
    $DOCKER_COMPOSE_CMD -f docker-compose.postgres.yml exec postgres pg_dump -U nomad_services -d nomad_services > "${BACKUP_FILE}"
    
    print_success "Backup created: ${BACKUP_FILE}"
    print_status "Backup size: $(du -h "${BACKUP_FILE}" | cut -f1)"
}

# Function to show connection info
show_connection_info() {
    print_success "PostgreSQL Connection Information:"
    echo
    echo "  Database URL: postgresql://nomad_services:secure_password@localhost:5432/nomad_services"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  Database: nomad_services"
    echo "  User: nomad_services"
    echo "  Password: secure_password"
    echo
    print_status "Environment Variables for Backend API:"
    echo "  export DB_HOST=localhost"
    echo "  export DB_PORT=5432"
    echo "  export DB_USER=nomad_services"
    echo "  export DB_PASSWORD=secure_password"
    echo "  export DB_NAME=nomad_services"
    echo "  export DB_SSL_MODE=disable"
    echo
    if $DOCKER_COMPOSE_CMD -f docker-compose.postgres.yml ps | grep -q pgadmin; then
        print_status "PgAdmin is available at: http://localhost:5050"
        echo "  Email: admin@nomadservices.local"
        echo "  Password: admin"
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start        Start PostgreSQL database"
    echo "  start-admin  Start PostgreSQL with PgAdmin"
    echo "  stop         Stop PostgreSQL database"
    echo "  restart      Restart PostgreSQL database"
    echo "  logs         Show PostgreSQL logs"
    echo "  connect      Connect to PostgreSQL database"
    echo "  status       Show PostgreSQL status"
    echo "  backup       Create database backup"
    echo "  info         Show connection information"
    echo "  help         Show this help message"
    echo
    echo "Examples:"
    echo "  $0 start         # Start PostgreSQL"
    echo "  $0 start-admin   # Start PostgreSQL with PgAdmin"
    echo "  $0 connect       # Connect to database"
    echo "  $0 backup        # Create backup"
}

# Main execution
main() {
    case "${1:-start}" in
        "start")
            check_docker
            check_docker_compose
            create_directories
            start_postgres
            wait_for_postgres
            show_connection_info
            ;;
        "start-admin")
            check_docker
            check_docker_compose
            create_directories
            start_postgres_with_admin
            wait_for_postgres
            show_connection_info
            ;;
        "stop")
            check_docker_compose
            stop_postgres
            ;;
        "restart")
            check_docker_compose
            stop_postgres
            sleep 2
            start_postgres
            wait_for_postgres
            show_connection_info
            ;;
        "logs")
            check_docker_compose
            show_logs
            ;;
        "connect")
            check_docker_compose
            connect_to_database
            ;;
        "status")
            check_docker_compose
            show_status
            ;;
        "backup")
            check_docker_compose
            backup_database
            ;;
        "info")
            show_connection_info
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
