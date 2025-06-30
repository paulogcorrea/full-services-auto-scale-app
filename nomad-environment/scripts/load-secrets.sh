#!/bin/bash

# Load secrets from Ansible Vault for Nomad jobs
# This script decrypts the secrets and makes them available as environment variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SECRETS_FILE="$PROJECT_ROOT/secrets/admin_credentials.yml"
TEMP_SECRETS="/tmp/nomad_secrets_$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Loading encrypted secrets for Nomad deployment...${NC}"

# Check if venv is activated
if [[ -z "$VIRTUAL_ENV" ]]; then
    echo -e "${YELLOW}⚠️  Activating Python virtual environment...${NC}"
    source "$PROJECT_ROOT/venv/bin/activate"
fi

# Check if secrets file exists
if [[ ! -f "$SECRETS_FILE" ]]; then
    echo -e "${RED}❌ Secrets file not found: $SECRETS_FILE${NC}"
    exit 1
fi

# Decrypt secrets to temporary file
echo -e "${YELLOW}🔓 Decrypting secrets...${NC}"
if ! ansible-vault decrypt "$SECRETS_FILE" --output="$TEMP_SECRETS" 2>/dev/null; then
    echo -e "${RED}❌ Failed to decrypt secrets. Check your vault password.${NC}"
    exit 1
fi

# Function to extract value from YAML
get_yaml_value() {
    local key="$1"
    local file="$2"
    grep "^${key}:" "$file" | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//'
}

# Load all secrets as environment variables
echo -e "${GREEN}✅ Loading secrets into environment...${NC}"

# Database credentials
export MYSQL_ROOT_PASSWORD=$(get_yaml_value "mysql_root_password" "$TEMP_SECRETS")
export POSTGRES_USER=$(get_yaml_value "postgres_user" "$TEMP_SECRETS")
export POSTGRES_PASSWORD=$(get_yaml_value "postgres_password" "$TEMP_SECRETS")

# Application credentials
export GRAFANA_ADMIN_USER=$(get_yaml_value "grafana_admin_user" "$TEMP_SECRETS")
export GRAFANA_ADMIN_PASSWORD=$(get_yaml_value "grafana_admin_password" "$TEMP_SECRETS")
export RABBITMQ_DEFAULT_USER=$(get_yaml_value "rabbitmq_default_user" "$TEMP_SECRETS")
export RABBITMQ_DEFAULT_PASS=$(get_yaml_value "rabbitmq_default_pass" "$TEMP_SECRETS")

# Monitoring credentials
export PROMETHEUS_ADMIN_USER=$(get_yaml_value "prometheus_admin_user" "$TEMP_SECRETS")
export PROMETHEUS_ADMIN_PASSWORD=$(get_yaml_value "prometheus_admin_password" "$TEMP_SECRETS")

# Repository management
export NEXUS_ADMIN_USER=$(get_yaml_value "nexus_admin_user" "$TEMP_SECRETS")
export NEXUS_ADMIN_PASSWORD=$(get_yaml_value "nexus_admin_password" "$TEMP_SECRETS")
export ARTIFACTORY_ADMIN_USER=$(get_yaml_value "artifactory_admin_user" "$TEMP_SECRETS")
export ARTIFACTORY_ADMIN_PASSWORD=$(get_yaml_value "artifactory_admin_password" "$TEMP_SECRETS")

# Communication & collaboration
export MATTERMOST_ADMIN_USER=$(get_yaml_value "mattermost_admin_user" "$TEMP_SECRETS")
export MATTERMOST_ADMIN_PASSWORD=$(get_yaml_value "mattermost_admin_password" "$TEMP_SECRETS")
export JENKINS_ADMIN_USER=$(get_yaml_value "jenkins_admin_user" "$TEMP_SECRETS")
export JENKINS_ADMIN_PASSWORD=$(get_yaml_value "jenkins_admin_password" "$TEMP_SECRETS")

# Identity & access management
export KEYCLOAK_ADMIN_USER=$(get_yaml_value "keycloak_admin_user" "$TEMP_SECRETS")
export KEYCLOAK_ADMIN_PASSWORD=$(get_yaml_value "keycloak_admin_password" "$TEMP_SECRETS")

# Object storage
export MINIO_ROOT_USER=$(get_yaml_value "minio_root_user" "$TEMP_SECRETS")
export MINIO_ROOT_PASSWORD=$(get_yaml_value "minio_root_password" "$TEMP_SECRETS")

# Code quality
export SONARQUBE_ADMIN_USER=$(get_yaml_value "sonarqube_admin_user" "$TEMP_SECRETS")
export SONARQUBE_ADMIN_PASSWORD=$(get_yaml_value "sonarqube_admin_password" "$TEMP_SECRETS")

# NoSQL database
export MONGODB_ROOT_USERNAME=$(get_yaml_value "mongodb_root_username" "$TEMP_SECRETS")
export MONGODB_ROOT_PASSWORD=$(get_yaml_value "mongodb_root_password" "$TEMP_SECRETS")

# Clean up temporary file
rm -f "$TEMP_SECRETS"

echo -e "${GREEN}✅ All secrets loaded successfully!${NC}"
echo -e "${BLUE}💡 Environment variables are now available for Nomad job deployments.${NC}"

# Verification function (optional - shows which secrets are loaded without revealing values)
show_loaded_secrets() {
    echo -e "\n${BLUE}📋 Loaded secret categories:${NC}"
    echo -e "  • Database: MySQL, PostgreSQL, MongoDB"
    echo -e "  • Monitoring: Grafana, Prometheus"
    echo -e "  • Messaging: RabbitMQ"
    echo -e "  • Repositories: Nexus, Artifactory"
    echo -e "  • Collaboration: Mattermost, Jenkins"
    echo -e "  • Identity: Keycloak"
    echo -e "  • Storage: MinIO"
    echo -e "  • Code Quality: SonarQube"
}

# Show what was loaded if requested
if [[ "$1" == "--show" ]]; then
    show_loaded_secrets
fi
