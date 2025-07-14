#!/bin/bash

# PostgreSQL Setup Script for Nomad Services Backend API
# This script sets up a dedicated PostgreSQL instance for the backend API

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
POSTGRES_CONTAINER_NAME="nomad-services-postgres"
POSTGRES_USER="nomad_services"
POSTGRES_PASSWORD="secure_password"
POSTGRES_DB="nomad_services"
POSTGRES_PORT="5432"
POSTGRES_DATA_DIR="./nomad-environment/data/postgresql"
POSTGRES_BACKUP_DIR="./nomad-environment/backups/postgresql"

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

# Function to check if container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${1}$"
}

# Function to check if container is running
container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${1}$"
}

# Function to create directories
create_directories() {
    print_status "Creating data directories..."
    mkdir -p "${POSTGRES_DATA_DIR}"
    mkdir -p "${POSTGRES_BACKUP_DIR}"
    print_success "Data directories created"
}

# Function to stop and remove existing container
cleanup_existing() {
    if container_exists "${POSTGRES_CONTAINER_NAME}"; then
        print_warning "Existing PostgreSQL container found. Stopping and removing..."
        docker stop "${POSTGRES_CONTAINER_NAME}" >/dev/null 2>&1 || true
        docker rm "${POSTGRES_CONTAINER_NAME}" >/dev/null 2>&1 || true
        print_success "Existing container cleaned up"
    fi
}

# Function to start PostgreSQL container
start_postgres() {
    print_status "Starting PostgreSQL container..."
    
    docker run -d \
        --name "${POSTGRES_CONTAINER_NAME}" \
        --restart unless-stopped \
        -e POSTGRES_USER="${POSTGRES_USER}" \
        -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
        -e POSTGRES_DB="${POSTGRES_DB}" \
        -p "${POSTGRES_PORT}:5432" \
        -v "${PWD}/${POSTGRES_DATA_DIR}:/var/lib/postgresql/data" \
        -v "${PWD}/${POSTGRES_BACKUP_DIR}:/backups" \
        -v "${PWD}/init-scripts:/docker-entrypoint-initdb.d" \
        postgres:13-alpine
    
    print_success "PostgreSQL container started"
}

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    print_status "Waiting for PostgreSQL to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec "${POSTGRES_CONTAINER_NAME}" pg_isready -U "${POSTGRES_USER}" >/dev/null 2>&1; then
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

# Function to create database schema
setup_database() {
    print_status "Setting up database schema..."
    
    # The Go application will handle auto-migration
    # But we can create additional setup here if needed
    
    print_success "Database schema setup complete"
}

# Function to create environment file
create_env_file() {
    print_status "Creating environment configuration file..."
    
    cat > .env.postgres << EOF
# PostgreSQL Configuration for Nomad Services Backend API
DB_HOST=localhost
DB_PORT=${POSTGRES_PORT}
DB_USER=${POSTGRES_USER}
DB_PASSWORD=${POSTGRES_PASSWORD}
DB_NAME=${POSTGRES_DB}
DB_SSL_MODE=disable

# Container Information
POSTGRES_CONTAINER_NAME=${POSTGRES_CONTAINER_NAME}
EOF
    
    print_success "Environment file created: .env.postgres"
}

# Function to show connection info
show_connection_info() {
    print_success "PostgreSQL setup complete!"
    echo
    print_status "Connection Information:"
    echo "  Host: localhost"
    echo "  Port: ${POSTGRES_PORT}"
    echo "  Database: ${POSTGRES_DB}"
    echo "  User: ${POSTGRES_USER}"
    echo "  Password: ${POSTGRES_PASSWORD}"
    echo
    print_status "Container Information:"
    echo "  Container Name: ${POSTGRES_CONTAINER_NAME}"
    echo "  Data Directory: ${POSTGRES_DATA_DIR}"
    echo "  Backup Directory: ${POSTGRES_BACKUP_DIR}"
    echo
    print_status "Management Commands:"
    echo "  Connect to database: docker exec -it ${POSTGRES_CONTAINER_NAME} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}"
    echo "  View logs: docker logs ${POSTGRES_CONTAINER_NAME}"
    echo "  Stop container: docker stop ${POSTGRES_CONTAINER_NAME}"
    echo "  Start container: docker start ${POSTGRES_CONTAINER_NAME}"
    echo "  Remove container: docker rm ${POSTGRES_CONTAINER_NAME}"
}

# Function to create backup script
create_backup_script() {
    print_status "Creating backup script..."
    
    cat > backup-postgresql.sh << 'EOF'
#!/bin/bash

# PostgreSQL Backup Script
# This script creates a backup of the PostgreSQL database

set -e

# Configuration
CONTAINER_NAME="nomad-services-postgres"
DB_NAME="nomad_services"
DB_USER="nomad_services"
BACKUP_DIR="./backups/postgresql"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/nomad_services_backup_${TIMESTAMP}.sql"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_error "PostgreSQL container is not running"
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Create backup
print_status "Creating database backup..."
docker exec "${CONTAINER_NAME}" pg_dump -U "${DB_USER}" -d "${DB_NAME}" > "${BACKUP_FILE}"

print_success "Backup created: ${BACKUP_FILE}"
print_status "Backup size: $(du -h "${BACKUP_FILE}" | cut -f1)"

# Keep only last 7 days of backups
find "${BACKUP_DIR}" -name "nomad_services_backup_*.sql" -mtime +7 -delete

print_success "Backup completed successfully"
EOF

    chmod +x backup-postgresql.sh
    print_success "Backup script created: backup-postgresql.sh"
}

# Function to create restore script
create_restore_script() {
    print_status "Creating restore script..."
    
    cat > restore-postgresql.sh << 'EOF'
#!/bin/bash

# PostgreSQL Restore Script
# This script restores a PostgreSQL database from backup

set -e

# Configuration
CONTAINER_NAME="nomad-services-postgres"
DB_NAME="nomad_services"
DB_USER="nomad_services"
BACKUP_DIR="./backups/postgresql"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if backup file is provided
if [ -z "$1" ]; then
    print_error "Usage: $0 <backup_file>"
    print_status "Available backups:"
    ls -la "${BACKUP_DIR}"/*.sql 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    print_error "Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_error "PostgreSQL container is not running"
    exit 1
fi

# Warning about data loss
print_warning "This operation will replace all data in the database!"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Restore cancelled"
    exit 0
fi

# Drop and recreate database
print_status "Dropping existing database..."
docker exec "${CONTAINER_NAME}" psql -U "${DB_USER}" -d postgres -c "DROP DATABASE IF EXISTS ${DB_NAME};"
docker exec "${CONTAINER_NAME}" psql -U "${DB_USER}" -d postgres -c "CREATE DATABASE ${DB_NAME};"

# Restore backup
print_status "Restoring from backup: ${BACKUP_FILE}"
docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" < "${BACKUP_FILE}"

print_success "Database restored successfully"
EOF

    chmod +x restore-postgresql.sh
    print_success "Restore script created: restore-postgresql.sh"
}

# Main execution
main() {
    print_status "Setting up PostgreSQL for Nomad Services Backend API"
    
    # Check prerequisites
    check_docker
    
    # Create directories
    create_directories
    
    # Clean up existing container if needed
    cleanup_existing
    
    # Start PostgreSQL container
    start_postgres
    
    # Wait for PostgreSQL to be ready
    wait_for_postgres
    
    # Setup database
    setup_database
    
    # Create environment file
    create_env_file
    
    # Create backup and restore scripts
    create_backup_script
    create_restore_script
    
    # Show connection information
    show_connection_info
}

# Handle script arguments
case "${1:-}" in
    "stop")
        print_status "Stopping PostgreSQL container..."
        docker stop "${POSTGRES_CONTAINER_NAME}" || true
        print_success "PostgreSQL container stopped"
        ;;
    "start")
        print_status "Starting PostgreSQL container..."
        docker start "${POSTGRES_CONTAINER_NAME}" || true
        print_success "PostgreSQL container started"
        ;;
    "restart")
        print_status "Restarting PostgreSQL container..."
        docker restart "${POSTGRES_CONTAINER_NAME}" || true
        print_success "PostgreSQL container restarted"
        ;;
    "logs")
        docker logs -f "${POSTGRES_CONTAINER_NAME}"
        ;;
    "connect")
        docker exec -it "${POSTGRES_CONTAINER_NAME}" psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"
        ;;
    "status")
        if container_running "${POSTGRES_CONTAINER_NAME}"; then
            print_success "PostgreSQL container is running"
            docker exec "${POSTGRES_CONTAINER_NAME}" pg_isready -U "${POSTGRES_USER}"
        else
            print_warning "PostgreSQL container is not running"
        fi
        ;;
    "remove")
        print_warning "This will permanently remove the PostgreSQL container and all data!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker stop "${POSTGRES_CONTAINER_NAME}" || true
            docker rm "${POSTGRES_CONTAINER_NAME}" || true
            print_success "PostgreSQL container removed"
        fi
        ;;
    *)
        main
        ;;
esac
