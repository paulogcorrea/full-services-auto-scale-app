#!/bin/bash

# Manual Certificate Update Script for Nomad Environment
# This script runs the certificate updater job immediately

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
JOBS_DIR="$BASE_DIR/jobs"
CERT_UPDATER_JOB="$JOBS_DIR/cert-updater.nomad"

print_header "=================== Manual Certificate Update ==================="

# Check if Nomad is running
if ! nomad node status &> /dev/null; then
    print_error "Nomad is not running. Please start Nomad first."
    echo "Run: ./init-scripts/start-nomad-environment.sh"
    exit 1
fi

# Check if certificate updater job exists
if [ ! -f "$CERT_UPDATER_JOB" ]; then
    print_error "Certificate updater job file not found: $CERT_UPDATER_JOB"
    exit 1
fi

print_status "Starting manual certificate update..."

# Check if job is already running
if nomad job status cert-updater &> /dev/null; then
    print_status "Certificate updater job exists, checking status..."
    
    # Get job status
    job_status=$(nomad job status cert-updater | grep "Status" | awk '{print $3}')
    if [ "$job_status" = "running" ]; then
        print_warning "Certificate updater is currently running. Waiting for completion..."
        
        # Wait for job to complete
        while [ "$(nomad job status cert-updater | grep "Status" | awk '{print $3}')" = "running" ]; do
            echo -n "."
            sleep 5
        done
        echo
        print_status "Previous job completed."
    fi
fi

# Run the certificate updater job
print_status "Running certificate updater job..."
if nomad job run "$CERT_UPDATER_JOB"; then
    print_status "Certificate updater job submitted successfully!"
    
    # Show job status
    print_status "Job status:"
    nomad job status cert-updater
    
    # Monitor job execution
    print_status "Monitoring job execution..."
    echo "Use 'nomad job status cert-updater' to check progress"
    echo "Use 'nomad alloc logs <alloc-id>' to view detailed logs"
    
    # Get allocation ID for logs
    sleep 3
    alloc_id=$(nomad job status cert-updater | grep "running\|complete" | head -1 | awk '{print $1}')
    if [ -n "$alloc_id" ]; then
        print_status "Allocation ID: $alloc_id"
        print_status "To view logs: nomad alloc logs $alloc_id"
        
        # Ask if user wants to see logs
        echo
        read -p "Do you want to view the job logs now? (y/N): " show_logs
        if [[ $show_logs =~ ^[Yy]$ ]]; then
            print_status "Showing certificate updater logs:"
            nomad alloc logs "$alloc_id" || true
        fi
    fi
    
else
    print_error "Failed to run certificate updater job"
    exit 1
fi

echo
print_header "=================== Certificate Update Summary ==================="
print_status "Certificate update job has been initiated"
print_status "Check job status with: nomad job status cert-updater"
print_status "Check certificates in: volumes/traefik-certs/"
print_status "Backups are stored in: volumes/cert-backup/"

# Check if Traefik is running and suggest restart
if nomad job status traefik-https &> /dev/null || nomad job status traefik &> /dev/null; then
    print_warning "Traefik is running. It should automatically reload certificates."
    print_warning "If needed, restart Traefik with:"
    if nomad job status traefik-https &> /dev/null; then
        print_warning "  nomad job restart traefik-https"
    fi
    if nomad job status traefik &> /dev/null; then
        print_warning "  nomad job restart traefik"
    fi
fi

print_status "Certificate update process completed!"
