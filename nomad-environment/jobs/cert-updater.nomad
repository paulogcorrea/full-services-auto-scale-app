job "cert-updater" {
  datacenters = ["dc1"]
  type        = "batch"
  
  # Run this job periodically to update certificates
  periodic {
    cron             = "0 2 * * 0"  # Run every Sunday at 2 AM
    prohibit_overlap = true
    time_zone        = "UTC"
  }

  group "cert-update" {
    count = 1

    # Volume for certificate storage
    volume "certs" {
      type      = "host"
      read_only = false
      source    = "traefik-certs"
    }

    # Volume for backup storage
    volume "cert-backup" {
      type      = "host" 
      read_only = false
      source    = "cert-backup"
    }

    task "update-certs" {
      driver = "docker"

      config {
        image = "alpine/openssl:latest"
        command = "/bin/sh"
        args = ["-c", "/local/update-certs.sh"]
        
        volumes = [
          "certs:/certs",
          "cert-backup:/backup"
        ]
      }

      # Certificate update script
      template {
        data = <<EOF
#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Certificate paths
CERT_DIR="/certs"
BACKUP_DIR="/backup"
CA_CERT="${CERT_DIR}/ca.pem"
SERVER_CERT="${CERT_DIR}/server-cert.pem"
SERVER_KEY="${CERT_DIR}/server-key.pem"
CA_KEY="${CERT_DIR}/ca-key.pem"

print_header "=================== Certificate Update Job ==================="

# Create backup directory with timestamp
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/backup_${BACKUP_TIMESTAMP}"
mkdir -p "${BACKUP_PATH}"

# Function to backup existing certificates
backup_certificates() {
    print_status "Backing up existing certificates..."
    
    if [ -f "$CA_CERT" ]; then
        cp "$CA_CERT" "${BACKUP_PATH}/ca.pem"
        print_status "Backed up CA certificate"
    fi
    
    if [ -f "$SERVER_CERT" ]; then
        cp "$SERVER_CERT" "${BACKUP_PATH}/server-cert.pem"
        print_status "Backed up server certificate"
    fi
    
    if [ -f "$SERVER_KEY" ]; then
        cp "$SERVER_KEY" "${BACKUP_PATH}/server-key.pem"
        print_status "Backed up server private key"
    fi
}

# Function to check certificate expiry
check_cert_expiry() {
    if [ ! -f "$SERVER_CERT" ]; then
        print_warning "Server certificate not found, will generate new one"
        return 1
    fi
    
    # Check if certificate expires in the next 30 days
    if openssl x509 -checkend 2592000 -noout -in "$SERVER_CERT" > /dev/null; then
        print_status "Certificate is valid for more than 30 days"
        return 0
    else
        print_warning "Certificate expires within 30 days, renewal needed"
        return 1
    fi
}

# Function to generate new certificates
generate_certificates() {
    print_status "Generating new certificates..."
    
    # Generate CA private key if it doesn't exist
    if [ ! -f "$CA_KEY" ]; then
        print_status "Generating new CA private key..."
        openssl genrsa -out "$CA_KEY" 4096
        chmod 400 "$CA_KEY"
    fi
    
    # Generate CA certificate if it doesn't exist
    if [ ! -f "$CA_CERT" ]; then
        print_status "Generating new CA certificate..."
        openssl req -new -x509 -days 365 -key "$CA_KEY" -sha256 -out "$CA_CERT" \
            -subj "/C=US/ST=CA/L=Local/O=Nomad Environment/CN=Nomad Development CA"
        chmod 444 "$CA_CERT"
    fi
    
    # Create certificate config
    cat > "/tmp/cert.conf" << 'EOL'
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
DNS.18 = gitea.localhost
DNS.19 = gitlab.localhost
DNS.20 = drone.localhost
DNS.21 = woodpecker.localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOL
    
    # Generate server private key
    print_status "Generating server private key..."
    openssl genrsa -out "$SERVER_KEY" 4096
    chmod 400 "$SERVER_KEY"
    
    # Generate certificate signing request
    print_status "Generating certificate signing request..."
    openssl req -subj "/C=US/ST=CA/L=Local/O=Nomad Environment/CN=*.localhost" \
        -sha256 -new -key "$SERVER_KEY" -out "/tmp/server.csr" -config "/tmp/cert.conf"
    
    # Generate server certificate
    print_status "Generating server certificate..."
    openssl x509 -req -days 365 -sha256 -in "/tmp/server.csr" \
        -CA "$CA_CERT" -CAkey "$CA_KEY" -out "$SERVER_CERT" \
        -extensions v3_req -extfile "/tmp/cert.conf" -CAcreateserial
    chmod 444 "$SERVER_CERT"
    
    # Clean up temporary files
    rm -f "/tmp/server.csr" "/tmp/cert.conf"
}

# Function to validate certificates
validate_certificates() {
    print_status "Validating certificates..."
    
    # Verify certificate against CA
    if openssl verify -CAfile "$CA_CERT" "$SERVER_CERT" > /dev/null 2>&1; then
        print_status "Certificate validation successful"
    else
        print_error "Certificate validation failed"
        return 1
    fi
    
    # Check certificate details
    print_status "Certificate details:"
    openssl x509 -in "$SERVER_CERT" -text -noout | grep -E "Subject:|Not Before:|Not After:|DNS:"
    
    return 0
}

# Function to restart Traefik (if running)
restart_traefik() {
    print_status "Checking if Traefik needs restart..."
    
    # Create a signal file to indicate certificate update
    echo "$(date): Certificates updated" > "${CERT_DIR}/cert-updated.flag"
    
    print_status "Certificate update flag created for Traefik"
    print_warning "Note: Traefik should automatically reload certificates"
    print_warning "If needed, restart Traefik manually: nomad job restart traefik-https"
}

# Main execution flow
print_status "Starting certificate update process..."

# Backup existing certificates
backup_certificates

# Check if renewal is needed
if check_cert_expiry; then
    print_status "Certificate is still valid, skipping renewal"
    
    # Still validate the certificate
    if ! validate_certificates; then
        print_warning "Validation failed, generating new certificates"
        generate_certificates
        validate_certificates
    fi
else
    print_status "Certificate renewal required"
    generate_certificates
    
    if ! validate_certificates; then
        print_error "Certificate generation/validation failed"
        exit 1
    fi
    
    restart_traefik
fi

# Clean up old backups (keep last 5)
print_status "Cleaning up old backups..."
cd "$BACKUP_DIR"
ls -t | grep "backup_" | tail -n +6 | xargs -r rm -rf
print_status "Old backup cleanup completed"

print_header "=================== Certificate Update Completed ==================="
print_status "Certificates are ready and valid"
print_status "CA Certificate: $CA_CERT"
print_status "Server Certificate: $SERVER_CERT"
print_status "Backup created: $BACKUP_PATH"

# Output certificate expiry information
EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$SERVER_CERT" | cut -d= -f2)
print_status "Certificate expires: $EXPIRY_DATE"

print_status "Certificate update job completed successfully!"
EOF
        destination = "local/update-certs.sh"
        perms = "0755"
      }

      # Environment variables
      env {
        TZ = "UTC"
      }

      resources {
        cpu    = 100
        memory = 128
      }

      # Log the certificate update process
      logs {
        max_files     = 3
        max_file_size = 10
      }

      # Constraints to ensure proper certificate handling
      constraint {
        attribute = "${attr.driver.docker}"
        value     = "1"
      }
    }
  }
}
