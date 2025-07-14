#!/bin/bash

# Setup script for Nomad volumes
# This script creates the host directories and registers volumes with Nomad

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Volume directories
VOLUMES_DIR="$PROJECT_ROOT/nomad-environment/volumes"
DATA_DIR="$PROJECT_ROOT/nomad-environment/data"

echo "Setting up Nomad volumes..."

# Create volume directories
mkdir -p "$VOLUMES_DIR"/{gitlab_config,gitlab_logs,gitlab_data,redis_data,postgresql_data}

# Set proper permissions
chmod 755 "$VOLUMES_DIR"/{gitlab_config,gitlab_logs,gitlab_data,redis_data,postgresql_data}

# Create host volume configuration for Nomad client
cat > "$DATA_DIR/client.hcl" << EOF
# Nomad client configuration with host volumes
datacenter = "dc1"
data_dir = "$DATA_DIR/client"
log_level = "INFO"
node_name = "client"
bind_addr = "0.0.0.0"

server {
  enabled = false
}

client {
  enabled = true
  
  host_volume "gitlab_config" {
    path      = "$VOLUMES_DIR/gitlab_config"
    read_only = false
  }
  
  host_volume "gitlab_logs" {
    path      = "$VOLUMES_DIR/gitlab_logs"
    read_only = false
  }
  
  host_volume "gitlab_data" {
    path      = "$VOLUMES_DIR/gitlab_data"
    read_only = false
  }
  
  host_volume "redis_data" {
    path      = "$VOLUMES_DIR/redis_data"
    read_only = false
  }
  
  host_volume "postgresql_data" {
    path      = "$VOLUMES_DIR/postgresql_data"
    read_only = false
  }
}

ports {
  http = 4646
  rpc  = 4647
  serf = 4648
}

consul {
  address = "127.0.0.1:8500"
}
EOF

echo "Volume directories created at: $VOLUMES_DIR"
echo "Client configuration updated with host volumes"
echo ""
echo "To register volumes with Nomad (after Nomad is running):"
echo "  nomad volume register $PROJECT_ROOT/volumes/volumes.hcl"
echo ""
echo "Volume setup complete!"
