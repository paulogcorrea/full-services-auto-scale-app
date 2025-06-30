# Secrets Management with Ansible Vault

This document explains how secrets are managed in the Nomad Environment using Ansible Vault for secure credential storage.

## Overview

All admin usernames and passwords for services have been moved from hardcoded values in Nomad job files to encrypted storage using Ansible Vault. This provides better security for development and production environments.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Ansible Vault  │───▶│  load-secrets.sh │───▶│  Environment    │
│  (Encrypted)    │    │  (Decryption)    │    │  Variables      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                                               ┌─────────────────┐
                                               │  Nomad Jobs     │
                                               │  (Template      │
                                               │   Substitution) │
                                               └─────────────────┘
```

## Files Structure

```
nomad-environment/
├── secrets/
│   └── admin_credentials.yml          # Encrypted credentials file
├── scripts/
│   ├── load-secrets.sh                # Decryption and loading script
│   └── verify-secrets.sh              # Verification script
├── venv/                              # Python virtual environment
└── jobs/                              # Nomad job files (updated to use env vars)
```

## Encrypted Credentials

The following service credentials are stored in encrypted format:

### Database Services
- **MySQL**: Root password
- **PostgreSQL**: Username and password
- **MongoDB**: Root username and password

### Monitoring & Observability
- **Grafana**: Admin username and password
- **Prometheus**: Admin credentials (if needed)

### Messaging
- **RabbitMQ**: Default username and password

### Repository Management
- **Nexus**: Admin credentials
- **Artifactory**: Admin credentials

### Collaboration & CI/CD
- **Mattermost**: Admin credentials
- **Jenkins**: Admin username and password

### Identity & Access Management
- **Keycloak**: Admin username and password

### Storage
- **MinIO**: Root username and password

### Code Quality
- **SonarQube**: Admin credentials

## Usage

### Automatic Loading (Recommended)

When you run `./start-nomad-environment.sh`, secrets are automatically loaded:

```bash
./start-nomad-environment.sh
```

The script will:
1. Prompt for the Ansible Vault password
2. Decrypt and load all secrets as environment variables
3. Show the service deployment menu
4. Deploy services with the encrypted credentials

### Manual Loading

You can also manually load secrets:

```bash
# Load secrets into current shell session
source scripts/load-secrets.sh

# Load secrets and show what was loaded
source scripts/load-secrets.sh --show
```

### Verification

Test that secrets integration is working:

```bash
bash scripts/verify-secrets.sh
```

## Security Features

### Encryption
- All credentials are encrypted using AES-256 via Ansible Vault
- Requires a master password to decrypt
- Credentials are never stored in plaintext in files

### Secure Handling
- Secrets are only decrypted to temporary files during loading
- Temporary files are automatically cleaned up
- Environment variables are only available during the current session

### No Hardcoded Credentials
- All Nomad job files use environment variable substitution
- No plaintext credentials in version control
- Easy credential rotation without changing job files

## Password Management

### Viewing Encrypted File
```bash
# Activate Python environment
source venv/bin/activate

# View decrypted content (for editing)
ansible-vault view secrets/admin_credentials.yml
```

### Editing Credentials
```bash
# Activate Python environment
source venv/bin/activate

# Edit encrypted credentials
ansible-vault edit secrets/admin_credentials.yml
```

### Changing Vault Password
```bash
# Activate Python environment
source venv/bin/activate

# Change the encryption password
ansible-vault rekey secrets/admin_credentials.yml
```

## Environment Variables

The following environment variables are set when secrets are loaded:

```bash
# Database
MYSQL_ROOT_PASSWORD
POSTGRES_USER
POSTGRES_PASSWORD
MONGODB_ROOT_USERNAME
MONGODB_ROOT_PASSWORD

# Applications
GRAFANA_ADMIN_USER
GRAFANA_ADMIN_PASSWORD
RABBITMQ_DEFAULT_USER
RABBITMQ_DEFAULT_PASS

# Monitoring
PROMETHEUS_ADMIN_USER
PROMETHEUS_ADMIN_PASSWORD

# Repositories
NEXUS_ADMIN_USER
NEXUS_ADMIN_PASSWORD
ARTIFACTORY_ADMIN_USER
ARTIFACTORY_ADMIN_PASSWORD

# Collaboration
MATTERMOST_ADMIN_USER
MATTERMOST_ADMIN_PASSWORD
JENKINS_ADMIN_USER
JENKINS_ADMIN_PASSWORD

# Identity
KEYCLOAK_ADMIN_USER
KEYCLOAK_ADMIN_PASSWORD

# Storage
MINIO_ROOT_USER
MINIO_ROOT_PASSWORD

# Code Quality
SONARQUBE_ADMIN_USER
SONARQUBE_ADMIN_PASSWORD
```

## Troubleshooting

### Secrets Not Loading
1. Ensure Python virtual environment is activated
2. Check that `ansible-vault` is installed in the venv
3. Verify the vault password is correct
4. Check file permissions on `secrets/admin_credentials.yml`

### Environment Variables Not Set
1. Run `scripts/verify-secrets.sh` to diagnose issues
2. Ensure you're sourcing the script: `source scripts/load-secrets.sh`
3. Check that the secrets file exists and is readable

### Job Deployment Failures
1. Verify secrets are loaded: `echo $MYSQL_ROOT_PASSWORD`
2. Check Nomad job files use correct variable names
3. Ensure environment variables are available in the deployment shell

## Best Practices

### Development Environment
- Use strong passwords even in development
- Don't share the vault password in chat/email
- Regularly rotate credentials

### Production Environment
- Use different vault passwords for different environments
- Implement proper key management for vault passwords
- Consider using HashiCorp Vault for production secrets management

### Version Control
- Never commit the vault password
- Never commit decrypted credentials
- The encrypted file (`admin_credentials.yml`) is safe to commit

## Migration from Hardcoded Credentials

The migration process involved:

1. **Identification**: Found all hardcoded credentials in job files
2. **Extraction**: Created encrypted credentials file with Ansible Vault
3. **Substitution**: Updated job files to use environment variables
4. **Integration**: Modified deployment script to load secrets automatically
5. **Verification**: Created testing script to ensure proper functionality

All services now use secure, encrypted credential management instead of hardcoded passwords.
