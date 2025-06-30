#!/bin/bash

# Generate self-signed certificates for HTTPS development
# This script creates certificates for all .localhost domains

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

# Create certificates directory
CERT_DIR="../certs"
mkdir -p "$CERT_DIR"

print_header "=================== Generating HTTPS Certificates ==================="

# Generate CA private key
print_status "Generating CA private key..."
openssl genrsa -out "$CERT_DIR/ca-key.pem" 4096

# Generate CA certificate
print_status "Generating CA certificate..."
openssl req -new -x509 -days 365 -key "$CERT_DIR/ca-key.pem" -sha256 -out "$CERT_DIR/ca.pem" -subj "/C=US/ST=CA/L=Local/O=Nomad Environment/CN=Nomad Development CA"

# Create certificate config
cat > "$CERT_DIR/cert.conf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
L = Local
O = Nomad Environment
CN = *.localhost

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
DNS.3 = php.localhost
DNS.4 = api.localhost
DNS.5 = grafana.localhost
DNS.6 = prometheus.localhost
DNS.7 = jenkins.localhost
DNS.8 = rabbitmq.localhost
DNS.9 = mattermost.localhost
DNS.10 = keycloak.localhost
DNS.11 = vault.localhost
DNS.12 = nexus.localhost
DNS.13 = artifactory.localhost
DNS.14 = cadvisor.localhost
DNS.15 = java.localhost
DNS.16 = minio.localhost
DNS.17 = sonarqube.localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# Generate server private key
print_status "Generating server private key..."
openssl genrsa -out "$CERT_DIR/server-key.pem" 4096

# Generate certificate signing request
print_status "Generating certificate signing request..."
openssl req -subj "/C=US/ST=CA/L=Local/O=Nomad Environment/CN=*.localhost" -sha256 -new -key "$CERT_DIR/server-key.pem" -out "$CERT_DIR/server.csr" -config "$CERT_DIR/cert.conf"

# Generate server certificate
print_status "Generating server certificate..."
openssl x509 -req -days 365 -sha256 -in "$CERT_DIR/server.csr" -CA "$CERT_DIR/ca.pem" -CAkey "$CERT_DIR/ca-key.pem" -out "$CERT_DIR/server-cert.pem" -extensions v3_req -extfile "$CERT_DIR/cert.conf" -CAcreateserial

# Set appropriate permissions
chmod 400 "$CERT_DIR/ca-key.pem"
chmod 400 "$CERT_DIR/server-key.pem"
chmod 444 "$CERT_DIR/ca.pem"
chmod 444 "$CERT_DIR/server-cert.pem"

print_header "=================== Certificates Generated ==================="
print_status "CA Certificate: $CERT_DIR/ca.pem"
print_status "Server Certificate: $CERT_DIR/server-cert.pem"
print_status "Server Private Key: $CERT_DIR/server-key.pem"
print_status ""
print_warning "To trust the certificates in your browser:"
print_warning "1. Open Keychain Access on macOS"
print_warning "2. Import $CERT_DIR/ca.pem"
print_warning "3. Set it to 'Always Trust' for SSL"
print_warning ""
print_warning "Alternative: Use --ignore-certificate-errors flag in Chrome"
print_status ""
print_status "Certificates are ready for HTTPS setup!"
