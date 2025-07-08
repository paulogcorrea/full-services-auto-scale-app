#!/bin/bash

# Keycloak with PostgreSQL Deployment Helper
# This script helps deploy Keycloak using PostgreSQL as the database backend

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to get host IP address
get_host_ip() {
    local host_ip=$(ifconfig | grep -E "inet " | grep -v "127.0.0.1" | head -1 | awk '{print $2}')
    if [ -z "$host_ip" ]; then
        host_ip="localhost"
    fi
    echo "$host_ip"
}

HOST_IP=$(get_host_ip)

print_header "🔐 Keycloak with PostgreSQL Deployment"
echo
print_status "This script will deploy Keycloak with PostgreSQL as the database backend."
print_status "Host IP detected: ${HOST_IP}"
echo

# Check if PostgreSQL is already running
print_status "Checking if PostgreSQL is running..."
if nomad job status postgresql-server &> /dev/null; then
    print_status "✅ PostgreSQL is already running"
else
    print_warning "PostgreSQL is not running. Deploying PostgreSQL first..."
    
    # Load secrets if available
    if [[ -f "scripts/load-secrets.sh" ]]; then
        print_status "Loading secrets for PostgreSQL..."
        source scripts/load-secrets.sh || true
    fi
    
    # Deploy PostgreSQL
    if nomad job run jobs/postgresql.nomad; then
        print_status "✅ PostgreSQL deployed successfully"
        
        # Wait for PostgreSQL to be ready
        print_status "Waiting for PostgreSQL to be ready..."
        sleep 15
        
        # Check if PostgreSQL is healthy
        allocation_id=$(nomad job status postgresql-server -json | jq -r '.TaskGroups[0].Allocations[0].ID')
        if [ "$allocation_id" != "null" ] && [ -n "$allocation_id" ]; then
            print_status "PostgreSQL allocation ID: $allocation_id"
        fi
    else
        print_error "Failed to deploy PostgreSQL"
        exit 1
    fi
fi

echo
print_status "Configuring Keycloak to use PostgreSQL..."

# Set environment variables for Keycloak to use PostgreSQL
export KC_DB_TYPE="postgresql"
export KC_DB_HOST="${HOST_IP}"
export KC_DB_PORT="5432"
export KC_DB_NAME="keycloak"

# Use vault secrets if available, otherwise use defaults
if [ -n "$POSTGRES_USER" ]; then
    export KC_DB_USERNAME="$POSTGRES_USER"
else
    export KC_DB_USERNAME="postgres"
    print_warning "Using default PostgreSQL username: postgres"
fi

if [ -n "$POSTGRES_PASSWORD" ]; then
    export KC_DB_PASSWORD="$POSTGRES_PASSWORD"
else
    export KC_DB_PASSWORD="postgres"
    print_warning "Using default PostgreSQL password: postgres"
fi

# Create the Keycloak database if it doesn't exist
print_status "Creating Keycloak database in PostgreSQL..."

# Find PostgreSQL container
POSTGRES_CONTAINER=$(docker ps --filter "ancestor=postgres" --format "{{.ID}}" | head -1)

if [ -n "$POSTGRES_CONTAINER" ]; then
    print_status "Found PostgreSQL container: $POSTGRES_CONTAINER"
    
    # Create keycloak database
    docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -c "CREATE DATABASE keycloak;" 2>/dev/null || {
        print_status "Database 'keycloak' already exists or creation failed (this is often normal)"
    }
    
    # Grant permissions
    docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE keycloak TO postgres;" 2>/dev/null || true
    
    print_status "✅ Database configuration completed"
else
    print_warning "Could not find PostgreSQL container. Database may not be ready yet."
fi

echo
print_status "Deploying Keycloak with PostgreSQL configuration..."

# Deploy Keycloak
if nomad job run jobs/keycloak.nomad; then
    print_status "✅ Keycloak deployed successfully with PostgreSQL backend!"
    echo
    
    print_header "🎉 Deployment Complete!"
    echo
    print_status "📍 Service Endpoints:"
    echo "🌐 Keycloak Admin: http://${HOST_IP}:8070"
    echo "👤 Admin Login: [vault username] / [vault password]"
    echo "🏛️ Realms: http://${HOST_IP}:8070/admin/master/console/"
    echo "💾 Database: PostgreSQL at ${HOST_IP}:5432"
    echo "📊 Database Name: keycloak"
    echo
    
    print_status "💡 Configuration Details:"
    echo "   • KC_DB_TYPE: $KC_DB_TYPE"
    echo "   • KC_DB_HOST: $KC_DB_HOST"
    echo "   • KC_DB_PORT: $KC_DB_PORT"
    echo "   • KC_DB_NAME: $KC_DB_NAME"
    echo "   • KC_DB_USERNAME: $KC_DB_USERNAME"
    echo
    
    print_status "🔗 Additional Resources:"
    echo "   • Nomad UI: http://${HOST_IP}:4646"
    echo "   • PostgreSQL: ${HOST_IP}:5432"
    echo "   • Service logs: nomad alloc logs [keycloak-allocation-id]"
    echo
    
    # Wait a moment for Keycloak to start
    print_status "Waiting for Keycloak to initialize..."
    sleep 10
    
    # Check Keycloak health
    if curl -s "http://${HOST_IP}:8070/health/ready" > /dev/null 2>&1; then
        print_status "✅ Keycloak is ready and responding!"
    else
        print_warning "Keycloak may still be starting up. Check the logs if needed."
    fi
    
else
    print_error "Failed to deploy Keycloak"
    exit 1
fi
