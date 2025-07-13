# Deployment Guide

## Overview

This guide covers different deployment strategies for the Nomad Services API, from development to production environments.

## Prerequisites

### System Requirements
- **CPU**: 2+ cores
- **Memory**: 4GB+ RAM
- **Storage**: 20GB+ SSD
- **Network**: Stable internet connection

### Software Dependencies
- Go 1.21 or higher
- PostgreSQL 12 or higher
- HashiCorp Nomad 1.4 or higher
- Docker (for containerized deployment)
- Git

## Environment Configuration

### Environment Variables

Create a `.env` file in the project root:

```bash
# Server Configuration
SERVER_PORT=8080
ENVIRONMENT=production
LOG_LEVEL=info
LOG_FILE=/var/log/nomad-services-api/app.log
CORS_ORIGINS=https://your-frontend-domain.com

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=nomad_services
DB_PASSWORD=secure_password_here
DB_NAME=nomad_services
DB_SSL_MODE=require

# JWT Configuration
JWT_SECRET=your-very-secure-jwt-secret-key-here
JWT_TOKEN_DURATION=24h
JWT_REFRESH_DURATION=168h

# Nomad Configuration
NOMAD_ADDR=http://127.0.0.1:4646
NOMAD_JOBS_PATH=/opt/nomad-services/jobs
NOMAD_NAMESPACE=default
NOMAD_TOKEN=your-nomad-acl-token

# SaaS Configuration
SAAS_MULTI_TENANT=true
SAAS_MAX_SERVICES_PER_TENANT=50
SAAS_PRICING_ENABLED=true
SAAS_BILLING_ENABLED=true
```

### Production Security Considerations

1. **JWT Secret**: Generate a strong, random JWT secret
```bash
openssl rand -base64 32
```

2. **Database Password**: Use a strong, unique password
```bash
openssl rand -base64 24
```

3. **Environment Isolation**: Keep production credentials separate from development

## Deployment Methods

### 1. Local Development

#### Quick Setup
```bash
# Clone repository
git clone <repository-url>
cd nomad-environment/backend

# Install dependencies
go mod tidy

# Set up database
createdb nomad_services
psql nomad_services < migrations/init.sql

# Copy environment file
cp .env.example .env
# Edit .env with your settings

# Run the application
go run main.go
```

#### Development with Auto-reload
```bash
# Install air for auto-reload
go install github.com/cosmtrek/air@latest

# Run with auto-reload
air
```

### 2. Docker Deployment

#### Single Container
```dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/

COPY --from=builder /app/main .
COPY --from=builder /app/jobs ./jobs

EXPOSE 8080
CMD ["./main"]
```

Build and run:
```bash
# Build image
docker build -t nomad-services-api .

# Run container
docker run -d \
  --name nomad-services-api \
  -p 8080:8080 \
  -e DB_HOST=your-db-host \
  -e DB_PASSWORD=your-db-password \
  -e JWT_SECRET=your-jwt-secret \
  nomad-services-api
```

#### Docker Compose
```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=postgres
      - DB_USER=nomad_services
      - DB_PASSWORD=secure_password
      - DB_NAME=nomad_services
      - JWT_SECRET=your-jwt-secret
      - NOMAD_ADDR=http://nomad:4646
    depends_on:
      - postgres
      - nomad
    volumes:
      - ./jobs:/app/jobs
      - ./logs:/var/log/nomad-services-api
    restart: unless-stopped
    networks:
      - nomad-network

  postgres:
    image: postgres:13
    environment:
      - POSTGRES_USER=nomad_services
      - POSTGRES_PASSWORD=secure_password
      - POSTGRES_DB=nomad_services
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    ports:
      - "5432:5432"
    restart: unless-stopped
    networks:
      - nomad-network

  nomad:
    image: hashicorp/nomad:1.7
    command: ["nomad", "agent", "-dev", "-bind=0.0.0.0", "-log-level=DEBUG"]
    ports:
      - "4646:4646"
    volumes:
      - nomad_data:/opt/nomad/data
    restart: unless-stopped
    networks:
      - nomad-network

volumes:
  postgres_data:
  nomad_data:

networks:
  nomad-network:
    driver: bridge
```

Start with:
```bash
docker-compose up -d
```

### 3. Kubernetes Deployment

#### Namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nomad-services
```

#### ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nomad-services-config
  namespace: nomad-services
data:
  SERVER_PORT: "8080"
  ENVIRONMENT: "production"
  LOG_LEVEL: "info"
  DB_HOST: "postgres-service"
  DB_PORT: "5432"
  DB_NAME: "nomad_services"
  NOMAD_ADDR: "http://nomad-service:4646"
  SAAS_MULTI_TENANT: "true"
```

#### Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: nomad-services-secrets
  namespace: nomad-services
type: Opaque
data:
  DB_USER: <base64-encoded-username>
  DB_PASSWORD: <base64-encoded-password>
  JWT_SECRET: <base64-encoded-jwt-secret>
  NOMAD_TOKEN: <base64-encoded-nomad-token>
```

#### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nomad-services-api
  namespace: nomad-services
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nomad-services-api
  template:
    metadata:
      labels:
        app: nomad-services-api
    spec:
      containers:
      - name: api
        image: nomad-services-api:latest
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: nomad-services-config
        - secretRef:
            name: nomad-services-secrets
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: jobs-volume
          mountPath: /app/jobs
        - name: logs-volume
          mountPath: /var/log/nomad-services-api
      volumes:
      - name: jobs-volume
        configMap:
          name: nomad-job-templates
      - name: logs-volume
        emptyDir: {}
```

#### Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nomad-services-api-service
  namespace: nomad-services
spec:
  selector:
    app: nomad-services-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: ClusterIP
```

#### Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nomad-services-api-ingress
  namespace: nomad-services
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - api.yourdomain.com
    secretName: nomad-services-api-tls
  rules:
  - host: api.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nomad-services-api-service
            port:
              number: 80
```

Deploy to Kubernetes:
```bash
kubectl apply -f k8s/
```

### 4. Systemd Service (Linux)

#### Service File
Create `/etc/systemd/system/nomad-services-api.service`:

```ini
[Unit]
Description=Nomad Services API
After=network.target postgresql.service

[Service]
Type=simple
User=nomad-services
Group=nomad-services
WorkingDirectory=/opt/nomad-services-api
ExecStart=/opt/nomad-services-api/nomad-services-api
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=nomad-services-api
EnvironmentFile=/etc/nomad-services-api/config.env

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/nomad-services-api /var/lib/nomad-services-api

[Install]
WantedBy=multi-user.target
```

#### Installation
```bash
# Create user
sudo useradd -r -s /bin/false nomad-services

# Create directories
sudo mkdir -p /opt/nomad-services-api
sudo mkdir -p /etc/nomad-services-api
sudo mkdir -p /var/log/nomad-services-api
sudo mkdir -p /var/lib/nomad-services-api

# Build and install binary
go build -o nomad-services-api main.go
sudo cp nomad-services-api /opt/nomad-services-api/
sudo cp -r jobs /opt/nomad-services-api/

# Set permissions
sudo chown -R nomad-services:nomad-services /opt/nomad-services-api
sudo chown -R nomad-services:nomad-services /var/log/nomad-services-api
sudo chown -R nomad-services:nomad-services /var/lib/nomad-services-api

# Install and start service
sudo systemctl daemon-reload
sudo systemctl enable nomad-services-api
sudo systemctl start nomad-services-api
```

## Database Setup

### PostgreSQL Installation
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# CentOS/RHEL
sudo yum install postgresql-server postgresql-contrib
sudo postgresql-setup initdb

# Start service
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### Database Creation
```sql
-- Connect as postgres user
sudo -u postgres psql

-- Create database and user
CREATE USER nomad_services WITH PASSWORD 'secure_password';
CREATE DATABASE nomad_services OWNER nomad_services;
GRANT ALL PRIVILEGES ON DATABASE nomad_services TO nomad_services;

-- Grant necessary permissions
ALTER USER nomad_services CREATEDB;
\q
```

### Connection Security
```bash
# Edit pg_hba.conf
sudo vim /etc/postgresql/13/main/pg_hba.conf

# Add line for application
host    nomad_services    nomad_services    127.0.0.1/32    md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

## Nomad Integration

### Nomad Installation
```bash
# Download and install Nomad
wget https://releases.hashicorp.com/nomad/1.7.3/nomad_1.7.3_linux_amd64.zip
unzip nomad_1.7.3_linux_amd64.zip
sudo mv nomad /usr/local/bin/

# Verify installation
nomad version
```

### Nomad Configuration
Create `/etc/nomad.d/nomad.hcl`:

```hcl
datacenter = "dc1"
data_dir = "/opt/nomad/data"
log_level = "INFO"
server_join_retry_max = 3

server {
  enabled = true
  bootstrap_expect = 1
}

client {
  enabled = true
  servers = ["127.0.0.1:4647"]
}

acl = {
  enabled = true
}

ui_config {
  enabled = true
}
```

### ACL Setup
```bash
# Bootstrap ACL system
nomad acl bootstrap

# Create policy for API
nomad acl policy apply \
  -description "Policy for Nomad Services API" \
  nomad-services-api \
  policy.hcl

# Create token
nomad acl token create \
  -name="nomad-services-api" \
  -policy="nomad-services-api"
```

## Monitoring and Logging

### Application Logging
Configure structured logging in production:

```go
// Configure logrus for production
if cfg.Server.Environment == "production" {
    logrus.SetFormatter(&logrus.JSONFormatter{})
    
    if cfg.Server.LogFile != "" {
        file, err := os.OpenFile(cfg.Server.LogFile, 
            os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
        if err == nil {
            logrus.SetOutput(file)
        }
    }
}
```

### Log Rotation
Configure logrotate for log files:

```bash
# Create /etc/logrotate.d/nomad-services-api
/var/log/nomad-services-api/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 nomad-services nomad-services
    postrotate
        systemctl reload nomad-services-api
    endscript
}
```

### Health Monitoring
Set up health checks:

```bash
# Simple health check script
#!/bin/bash
curl -f http://localhost:8080/health || exit 1
```

### Metrics Collection
For production monitoring, consider integrating:
- Prometheus for metrics collection
- Grafana for visualization
- Elasticsearch for log aggregation

## Load Balancing

### Nginx Configuration
```nginx
upstream nomad_services_api {
    server 127.0.0.1:8080;
    server 127.0.0.1:8081;
    server 127.0.0.1:8082;
}

server {
    listen 80;
    server_name api.yourdomain.com;
    
    location / {
        proxy_pass http://nomad_services_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /health {
        access_log off;
        proxy_pass http://nomad_services_api;
    }
}
```

## Backup Strategy

### Database Backup
```bash
#!/bin/bash
# Automated backup script

BACKUP_DIR="/var/backups/nomad-services"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="nomad_services"

mkdir -p $BACKUP_DIR

# Create backup
pg_dump $DB_NAME | gzip > $BACKUP_DIR/backup_$DATE.sql.gz

# Keep only last 30 days
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete
```

### Application Backup
```bash
# Backup job templates and configuration
tar -czf /var/backups/nomad-services/app_backup_$(date +%Y%m%d).tar.gz \
    /opt/nomad-services-api/jobs \
    /etc/nomad-services-api
```

## Security Hardening

### Firewall Configuration
```bash
# Allow only necessary ports
ufw allow 22/tcp    # SSH
ufw allow 8080/tcp  # API
ufw allow 5432/tcp  # PostgreSQL (local only)
ufw enable
```

### SSL/TLS Configuration
Use Let's Encrypt for free SSL certificates:

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d api.yourdomain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Security Headers
Configure nginx with security headers:

```nginx
add_header X-Content-Type-Options nosniff;
add_header X-Frame-Options DENY;
add_header X-XSS-Protection "1; mode=block";
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
add_header Content-Security-Policy "default-src 'self'";
```

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check PostgreSQL service status
   - Verify connection string
   - Check network connectivity

2. **Nomad Connection Failed**
   - Verify Nomad service is running
   - Check ACL token permissions
   - Validate network connectivity

3. **High Memory Usage**
   - Review connection pool settings
   - Monitor goroutine leaks
   - Check for memory leaks in logs

4. **Slow API Response**
   - Review database query performance
   - Check database indexes
   - Monitor resource usage

### Log Analysis
```bash
# View application logs
journalctl -u nomad-services-api -f

# Search for errors
grep "ERROR" /var/log/nomad-services-api/app.log

# Monitor resource usage
htop
iostat -x 1
```

### Performance Tuning

1. **Database Optimization**
   - Increase shared_buffers
   - Tune work_mem
   - Enable query logging

2. **Application Tuning**
   - Adjust connection pool size
   - Implement caching
   - Optimize queries

3. **System Tuning**
   - Increase file descriptor limits
   - Tune kernel parameters
   - Optimize disk I/O

## Maintenance

### Regular Tasks
1. **Daily**
   - Monitor application logs
   - Check system resources
   - Verify backup completion

2. **Weekly**
   - Review security logs
   - Update system packages
   - Analyze performance metrics

3. **Monthly**
   - Update dependencies
   - Review and rotate logs
   - Performance optimization

### Update Procedure
```bash
# Backup current version
cp /opt/nomad-services-api/nomad-services-api /opt/nomad-services-api/nomad-services-api.backup

# Deploy new version
sudo systemctl stop nomad-services-api
cp new-binary /opt/nomad-services-api/nomad-services-api
sudo systemctl start nomad-services-api

# Verify deployment
curl http://localhost:8080/health
```
