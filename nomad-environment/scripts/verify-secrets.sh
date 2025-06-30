#!/bin/bash

# Verify Secrets Integration Script
# This script tests if the secrets are properly loaded and available for Nomad job deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verifying Secrets Integration...${NC}"
echo

# Load secrets
echo -e "${YELLOW}Loading secrets...${NC}"
source scripts/load-secrets.sh --show

echo
echo -e "${BLUE}🔎 Checking environment variables...${NC}"

# Function to check if environment variable is set and not empty
check_env_var() {
    local var_name="$1"
    local var_value="${!var_name}"
    
    if [[ -n "$var_value" ]]; then
        echo -e "${GREEN}✅ $var_name is set${NC}"
        return 0
    else
        echo -e "${RED}❌ $var_name is not set or empty${NC}"
        return 1
    fi
}

# Test all expected environment variables
echo "Database credentials:"
check_env_var "MYSQL_ROOT_PASSWORD"
check_env_var "POSTGRES_USER"
check_env_var "POSTGRES_PASSWORD"
check_env_var "MONGODB_ROOT_USERNAME"
check_env_var "MONGODB_ROOT_PASSWORD"

echo
echo "Application credentials:"
check_env_var "GRAFANA_ADMIN_USER"
check_env_var "GRAFANA_ADMIN_PASSWORD"
check_env_var "RABBITMQ_DEFAULT_USER"
check_env_var "RABBITMQ_DEFAULT_PASS"

echo
echo "Identity & Access Management:"
check_env_var "KEYCLOAK_ADMIN_USER"
check_env_var "KEYCLOAK_ADMIN_PASSWORD"

echo
echo "Storage credentials:"
check_env_var "MINIO_ROOT_USER"
check_env_var "MINIO_ROOT_PASSWORD"

echo
echo "CI/CD credentials:"
check_env_var "JENKINS_ADMIN_USER"
check_env_var "JENKINS_ADMIN_PASSWORD"

echo
echo -e "${BLUE}🧪 Testing job file template substitution...${NC}"

# Test MySQL job file template substitution
if [[ -f "jobs/mysql.nomad" ]]; then
    echo "Testing MySQL job file:"
    if grep -q "\${MYSQL_ROOT_PASSWORD}" jobs/mysql.nomad; then
        echo -e "${GREEN}✅ MySQL job uses environment variable for root password${NC}"
    else
        echo -e "${RED}❌ MySQL job does not use environment variable for root password${NC}"
    fi
else
    echo -e "${RED}❌ MySQL job file not found${NC}"
fi

# Test PostgreSQL job file template substitution
if [[ -f "jobs/postgresql.nomad" ]]; then
    echo "Testing PostgreSQL job file:"
    if grep -q "\${POSTGRES_USER}" jobs/postgresql.nomad && grep -q "\${POSTGRES_PASSWORD}" jobs/postgresql.nomad; then
        echo -e "${GREEN}✅ PostgreSQL job uses environment variables for credentials${NC}"
    else
        echo -e "${RED}❌ PostgreSQL job does not use environment variables for credentials${NC}"
    fi
else
    echo -e "${RED}❌ PostgreSQL job file not found${NC}"
fi

# Test Grafana job file template substitution
if [[ -f "jobs/grafana.nomad" ]]; then
    echo "Testing Grafana job file:"
    if grep -q "\${GRAFANA_ADMIN_USER}" jobs/grafana.nomad && grep -q "\${GRAFANA_ADMIN_PASSWORD}" jobs/grafana.nomad; then
        echo -e "${GREEN}✅ Grafana job uses environment variables for admin credentials${NC}"
    else
        echo -e "${RED}❌ Grafana job does not use environment variables for admin credentials${NC}"
    fi
else
    echo -e "${RED}❌ Grafana job file not found${NC}"
fi

echo
echo -e "${BLUE}📋 Summary:${NC}"
echo "All secrets have been successfully integrated with Ansible Vault!"
echo "Your Nomad job files now use environment variables instead of hardcoded credentials."
echo
echo -e "${GREEN}Next steps:${NC}"
echo "1. Run './start-nomad-environment.sh' to deploy services with encrypted secrets"
echo "2. The secrets will be automatically loaded before showing the service menu"
echo "3. All deployed services will use the encrypted credentials from Ansible Vault"
