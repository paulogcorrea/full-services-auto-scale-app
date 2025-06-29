#!/bin/bash

# Setup script for Nomad Environment Manager
# This script installs the required dependencies on macOS

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

# Check if Homebrew is installed
check_homebrew() {
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew is not installed. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        print_status "Homebrew is already installed"
    fi
}

# Install Nomad
install_nomad() {
    if ! command -v nomad &> /dev/null; then
        print_status "Installing HashiCorp Nomad..."
        brew tap hashicorp/tap
        brew install hashicorp/tap/nomad
        print_status "Nomad installed successfully"
    else
        print_status "Nomad is already installed"
        nomad version
    fi
}

# Check Docker installation
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed."
        print_warning "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
        print_warning "After installation, make sure to start Docker Desktop"
        return 1
    else
        print_status "Docker is installed"
        if docker info &> /dev/null; then
            print_status "Docker is running"
        else
            print_warning "Docker is installed but not running. Please start Docker Desktop"
            return 1
        fi
    fi
}

# Create required directories
setup_directories() {
    print_status "Setting up directory structure..."
    
    # Create data directories for persistent volumes
    mkdir -p ../nomad-data
    mkdir -p ../volumes/{mysql-data,postgres-data,nexus-data,artifactory-data,rabbitmq-data,jenkins-data,mattermost-data,mattermost-logs,mattermost-config}
    
    print_status "Directory structure created"
}

# Main setup function
main() {
    print_header "=================== Nomad Environment Setup ==================="
    
    # Check OS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This setup script is designed for macOS. Please install dependencies manually for other systems."
        exit 1
    fi
    
    print_status "Starting setup for macOS..."
    
    # Install dependencies
    check_homebrew
    install_nomad
    
    # Check Docker (don't install automatically as it requires manual intervention)
    if ! check_docker; then
        print_error "Please install and start Docker Desktop before proceeding"
        exit 1
    fi
    
    # Setup directories
    setup_directories
    
    # Make main script executable
    chmod +x ../start-nomad-environment.sh
    
    print_header "=================== Setup Complete ==================="
    print_status "All dependencies are installed and configured!"
    print_status ""
    print_status "To start the Nomad environment:"
    print_status "  cd .."
    print_status "  ./start-nomad-environment.sh"
    print_status ""
    print_status "Make sure Docker Desktop is running before starting the environment."
}

# Run main function
main "$@"
