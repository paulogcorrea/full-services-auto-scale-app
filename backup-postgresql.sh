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
