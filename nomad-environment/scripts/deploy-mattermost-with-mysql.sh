#!/bin/bash

# Mattermost with Dedicated MySQL Deployment Helper
# This script deploys Mattermost with its own MySQL instance (separate from main MySQL)

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

print_header "💬 Mattermost with Dedicated MySQL Deployment"
echo
print_status "This script will deploy Mattermost with its own MySQL database instance."
print_status "Host IP detected: ${HOST_IP}"
print_status "MySQL will run on port 3307 (separate from main MySQL on 3306)"
echo

# Check if Mattermost MySQL is already running
print_status "Checking if Mattermost MySQL is running..."
if nomad job status mysql-mattermost &> /dev/null; then
    print_status "✅ Mattermost MySQL is already running"
else
    print_warning "Mattermost MySQL is not running. Deploying dedicated MySQL first..."
    
    # Deploy Mattermost MySQL
    if nomad job run jobs/mysql-mattermost.nomad; then
        print_status "✅ Mattermost MySQL deployed successfully"
        
        # Wait for MySQL to be ready
        print_status "Waiting for MySQL to be ready..."
        sleep 20
        
        # Check if MySQL is healthy
        allocation_id=$(nomad job status mysql-mattermost -json | jq -r '.TaskGroups[0].Allocations[0].ID' 2>/dev/null || echo "")
        if [ "$allocation_id" != "null" ] && [ -n "$allocation_id" ]; then
            print_status "Mattermost MySQL allocation ID: $allocation_id"
        fi
    else
        print_error "Failed to deploy Mattermost MySQL"
        exit 1
    fi
fi

# Test MySQL connectivity
print_status "Testing MySQL connectivity..."
if nc -zv ${HOST_IP} 3307 2>/dev/null; then
    print_status "✅ MySQL connectivity confirmed"
else
    print_warning "MySQL may still be starting up..."
    sleep 10
fi

echo
print_status "Deploying Mattermost..."

# Deploy Mattermost
if nomad job run jobs/mattermost.nomad; then
    print_status "✅ Mattermost deployed successfully!"
    echo
    
    print_header "🎉 Deployment Complete!"
    echo
    print_status "📍 Service Endpoints:"
    echo "💬 Mattermost: http://${HOST_IP}:8065"
    echo "🗄️ Mattermost MySQL: ${HOST_IP}:3307"
    echo "👤 MySQL User: mmuser / mmuser_password"
    echo "📊 Database Name: mattermost"
    echo
    
    print_status "💡 Configuration Details:"
    echo "   • Mattermost runs on dedicated MySQL (port 3307)"
    echo "   • Separate from main MySQL service (port 3306)"
    echo "   • Data persisted in separate Docker volumes"
    echo "   • Database optimized for Mattermost (utf8mb4)"
    echo
    
    print_status "🔗 Additional Resources:"
    echo "   • Nomad UI: http://${HOST_IP}:4646"
    echo "   • Service logs: nomad alloc logs [mattermost-allocation-id]"
    echo "   • MySQL logs: nomad alloc logs [mysql-mattermost-allocation-id]"
    echo
    
    # Wait a moment for Mattermost to start
    print_status "Waiting for Mattermost to initialize..."
    sleep 15
    
    # Check Mattermost health
    if curl -s "http://${HOST_IP}:8065/api/v4/system/ping" > /dev/null 2>&1; then
        print_status "✅ Mattermost is ready and responding!"
        echo
        print_header "🚀 Next Steps:"
        echo "1. Open http://${HOST_IP}:8065 in your browser"
        echo "2. Create your first team and admin account"
        echo "3. Start collaborating with your team!"
        echo
    else
        print_warning "Mattermost may still be starting up. Check the logs if needed."
        echo "   Command: nomad alloc logs \$(nomad job status mattermost-server -json | jq -r '.TaskGroups[0].Allocations[0].ID')"
    fi
    
else
    print_error "Failed to deploy Mattermost"
    exit 1
fi
