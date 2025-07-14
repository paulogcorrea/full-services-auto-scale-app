#!/bin/bash

# Deployment script for GitLab CE and Redis
# This script deploys GitLab CE with Redis dependency

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Nomad is running
if ! nomad node status > /dev/null 2>&1; then
    print_error "Nomad is not running. Please start Nomad first."
    exit 1
fi

# Check if volumes are set up
if [ ! -d "$PROJECT_ROOT/nomad-environment/volumes" ]; then
    print_warning "Volumes not set up. Running volume setup..."
    "$SCRIPT_DIR/setup-volumes.sh"
fi

print_status "Starting GitLab CE deployment..."

# Deploy Redis first (GitLab dependency)
print_status "Deploying Redis..."
if nomad job run "$PROJECT_ROOT/jobs/redis.nomad"; then
    print_status "Redis deployment initiated successfully"
else
    print_error "Failed to deploy Redis"
    exit 1
fi

# Wait for Redis to be healthy
print_status "Waiting for Redis to be healthy..."
sleep 10

# Check Redis health
redis_health=$(nomad job status redis | grep -c "running" || echo "0")
if [ "$redis_health" -eq "0" ]; then
    print_warning "Redis may not be fully healthy yet. Check with: nomad job status redis"
fi

# Deploy GitLab CE
print_status "Deploying GitLab CE..."
if nomad job run "$PROJECT_ROOT/jobs/gitlab-ce.nomad"; then
    print_status "GitLab CE deployment initiated successfully"
else
    print_error "Failed to deploy GitLab CE"
    exit 1
fi

print_status "GitLab CE deployment completed!"
echo ""
echo "Service URLs:"
echo "  GitLab CE: http://localhost:8080"
echo "  GitLab CE (HTTPS): https://localhost:8443"
echo "  GitLab CE (SSH): localhost:2022"
echo "  Redis: localhost:6379"
echo ""
echo "To check deployment status:"
echo "  nomad job status gitlab-ce"
echo "  nomad job status redis"
echo ""
echo "To view logs:"
echo "  nomad logs -f <allocation_id>"
echo ""
echo "Note: GitLab CE may take several minutes to fully initialize."
echo "Check the logs and wait for the web interface to become available."
