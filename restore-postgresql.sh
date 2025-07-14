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
