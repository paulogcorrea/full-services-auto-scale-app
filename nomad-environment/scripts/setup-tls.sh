#!/bin/bash

# TLS Setup Script for Nomad HTTPS Access
# This script helps users configure their system to trust the self-signed certificates

set -e

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
    echo -e "${BLUE}$1${NC}"
}

# Configuration
BASE_DIR="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")"
CERT_DIR="$BASE_DIR/certs"
CA_CERT="$CERT_DIR/ca.pem"
SERVER_CERT="$CERT_DIR/server-cert.pem"

print_header "🔐 Nomad HTTPS/TLS Setup Helper"
echo
print_status "This script helps you configure your system to trust the Nomad self-signed certificates."
echo

# Check if certificates exist
if [ ! -f "$CA_CERT" ]; then
    print_error "CA certificate not found: $CA_CERT"
    exit 1
fi

if [ ! -f "$SERVER_CERT" ]; then
    print_error "Server certificate not found: $SERVER_CERT"
    exit 1
fi

print_status "Found certificates in: $CERT_DIR"
echo

# Detect operating system
case "$(uname -s)" in
    Darwin*)
        print_header "🍎 macOS Configuration"
        echo
        print_status "Option 1: Add CA certificate to system keychain (recommended)"
        echo "sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \"$CA_CERT\""
        echo
        print_status "Option 2: Add CA certificate to user keychain"
        echo "security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain \"$CA_CERT\""
        echo
        print_status "Option 3: Trust certificate temporarily in browser"
        echo "• Open https://localhost:4646 in your browser"
        echo "• Click 'Advanced' when you see the security warning"
        echo "• Click 'Proceed to localhost (unsafe)'"
        echo
        
        read -p "Would you like to add the CA certificate to your user keychain? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            if security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain "$CA_CERT"; then
                print_status "✅ CA certificate added to user keychain successfully!"
                print_status "You may need to restart your browser for changes to take effect."
            else
                print_error "Failed to add certificate to keychain"
            fi
        fi
        ;;
        
    Linux*)
        print_header "🐧 Linux Configuration"
        echo
        print_status "Option 1: Add CA certificate to system trust store"
        echo "sudo cp \"$CA_CERT\" /usr/local/share/ca-certificates/nomad-ca.crt"
        echo "sudo update-ca-certificates"
        echo
        print_status "Option 2: For Ubuntu/Debian systems"
        echo "sudo cp \"$CA_CERT\" /usr/local/share/ca-certificates/nomad-ca.crt"
        echo "sudo update-ca-certificates"
        echo
        print_status "Option 3: For RHEL/CentOS/Fedora systems"
        echo "sudo cp \"$CA_CERT\" /etc/pki/ca-trust/source/anchors/nomad-ca.pem"
        echo "sudo update-ca-trust"
        echo
        print_status "Option 4: Trust certificate temporarily in browser"
        echo "• Open https://localhost:4646 in your browser"
        echo "• Click 'Advanced' when you see the security warning"
        echo "• Click 'Proceed to localhost (unsafe)'"
        echo
        ;;
        
    CYGWIN*|MINGW*|MSYS*)
        print_header "🪟 Windows Configuration"
        echo
        print_status "Option 1: Add CA certificate to Windows Certificate Store"
        echo "• Open Certificate Manager (certmgr.msc)"
        echo "• Navigate to Trusted Root Certification Authorities > Certificates"
        echo "• Right-click and select 'All Tasks' > 'Import'"
        echo "• Import the file: $CA_CERT"
        echo
        print_status "Option 2: Using PowerShell (run as Administrator)"
        echo "Import-Certificate -FilePath \"$CA_CERT\" -CertStoreLocation Cert:\\LocalMachine\\Root"
        echo
        print_status "Option 3: Trust certificate temporarily in browser"
        echo "• Open https://localhost:4646 in your browser"
        echo "• Click 'Advanced' when you see the security warning"
        echo "• Click 'Proceed to localhost (unsafe)'"
        echo
        ;;
        
    *)
        print_warning "Unknown operating system. Please manually configure certificate trust."
        ;;
esac

echo
print_header "📋 Certificate Information"
echo
print_status "CA Certificate: $CA_CERT"
print_status "Server Certificate: $SERVER_CERT"
echo

print_status "Certificate Details:"
openssl x509 -in "$SERVER_CERT" -text -noout | grep -E "(Subject:|DNS:|IP Address:)" | head -10

echo
print_header "🌐 Access Information"
echo
print_status "After configuring certificate trust:"
print_status "• Nomad UI: https://localhost:4646"
print_status "• Nomad API: https://localhost:4646/v1/"
echo

print_header "🔧 Troubleshooting"
echo
print_status "If you still see certificate warnings:"
print_status "1. Restart your browser completely"
print_status "2. Clear browser cache and cookies for localhost"
print_status "3. Try accessing from an incognito/private window"
print_status "4. Verify the certificate was imported correctly"
echo

print_warning "Note: These are self-signed certificates for development use only."
print_warning "Do not use these certificates in production environments."

echo
print_status "TLS setup information displayed. Choose your preferred method above."
