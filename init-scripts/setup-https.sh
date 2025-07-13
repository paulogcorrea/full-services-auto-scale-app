#!/bin/bash

# HTTPS Setup Script for Nomad Environment
# This script sets up HTTPS with self-signed certificates

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

print_header "=================== HTTPS Setup for Nomad Environment ==================="

print_status "Setting up HTTPS with self-signed certificates..."

# Step 1: Generate certificates
print_status "Step 1: Generating SSL certificates..."
cd scripts
chmod +x generate-certs.sh
./generate-certs.sh

# Step 2: Copy certificates to Traefik volume
print_status "Step 2: Copying certificates to Traefik volume..."
cd ..
mkdir -p volumes/traefik-certs
cp certs/server-cert.pem volumes/traefik-certs/
cp certs/server-key.pem volumes/traefik-certs/
cp certs/ca.pem volumes/traefik-certs/

# Step 3: Update /etc/hosts file
print_status "Step 3: Setting up local domain names..."
print_warning "Adding domains to /etc/hosts requires sudo access..."

HOSTS_ENTRIES="
127.0.0.1 php.localhost
127.0.0.1 api.localhost
127.0.0.1 grafana.localhost
127.0.0.1 prometheus.localhost
127.0.0.1 jenkins.localhost
127.0.0.1 rabbitmq.localhost
127.0.0.1 mattermost.localhost
127.0.0.1 keycloak.localhost
127.0.0.1 vault.localhost
127.0.0.1 nexus.localhost
127.0.0.1 artifactory.localhost
127.0.0.1 cadvisor.localhost
127.0.0.1 java.localhost
127.0.0.1 minio.localhost
127.0.0.1 sonarqube.localhost
"

# Check if entries already exist
if ! grep -q "php.localhost" /etc/hosts; then
    print_status "Adding domain entries to /etc/hosts..."
    echo "$HOSTS_ENTRIES" | sudo tee -a /etc/hosts > /dev/null
    print_status "Domains added to /etc/hosts"
else
    print_status "Domains already exist in /etc/hosts"
fi

print_header "=================== HTTPS Setup Complete ==================="
print_status "HTTPS is now configured for your Nomad environment!"
print_status ""
print_status "Next steps:"
print_status "1. Start your Nomad environment: ./start-nomad-environment.sh"
print_status "2. Deploy Traefik HTTPS: Select 'traefik-https' instead of 'traefik'"
print_status "3. Deploy your services"
print_status "4. Access via HTTPS:"
print_status "   - https://php.localhost"
print_status "   - https://grafana.localhost" 
print_status "   - https://api.localhost"
print_status "   - etc."
print_status ""
print_warning "Certificate Trust:"
print_warning "Your browser will show certificate warnings for self-signed certs."
print_warning ""
print_warning "To trust the certificates:"
print_warning "1. Open Keychain Access on macOS"
print_warning "2. Import certs/ca.pem"
print_warning "3. Set it to 'Always Trust' for SSL"
print_warning ""
print_warning "Alternative: Use Chrome with --ignore-certificate-errors flag"
