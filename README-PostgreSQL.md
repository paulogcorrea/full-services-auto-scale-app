# PostgreSQL Setup for Nomad Services Backend API

This document describes how to set up and manage a dedicated PostgreSQL database instance for the Nomad Services Backend API.

## Overview

The PostgreSQL setup provides a dedicated database instance specifically configured for the backend API with the following features:

- **Isolated Database**: Dedicated PostgreSQL instance for the backend API
- **Persistent Storage**: Data persistence across container restarts
- **Health Monitoring**: Built-in health checks and monitoring
- **Backup/Restore**: Automated backup and restore scripts
- **Admin Interface**: Optional PgAdmin web interface
- **Security**: Configured with proper user permissions and SSL support

## Quick Start

### Option 1: Using Docker Compose (Recommended)

```bash
# Start PostgreSQL database
./start-postgres.sh

# Start PostgreSQL with PgAdmin interface
./start-postgres.sh start-admin

# Stop PostgreSQL
./start-postgres.sh stop

# View logs
./start-postgres.sh logs

# Connect to database
./start-postgres.sh connect
```

### Option 2: Using Standalone Docker Container

```bash
# Setup PostgreSQL using Docker container
./setup-postgresql.sh

# Manage the container
./setup-postgresql.sh stop
./setup-postgresql.sh start
./setup-postgresql.sh restart
./setup-postgresql.sh logs
./setup-postgresql.sh connect
./setup-postgresql.sh status
```

## Configuration

### Environment Variables

The PostgreSQL setup uses the following environment variables (defined in `.env.postgres`):

```bash
# PostgreSQL Configuration
POSTGRES_USER=nomad_services
POSTGRES_PASSWORD=secure_password
POSTGRES_DB=nomad_services
POSTGRES_PORT=5432

# PgAdmin Configuration (optional)
PGADMIN_EMAIL=admin@nomadservices.local
PGADMIN_PASSWORD=admin
PGADMIN_PORT=5050

# Backend API Connection
DB_HOST=localhost
DB_PORT=5432
DB_USER=nomad_services
DB_PASSWORD=secure_password
DB_NAME=nomad_services
DB_SSL_MODE=disable
```

### Database Connection

The backend API connects to PostgreSQL using these settings:

```go
// Connection string format
dsn := "host=localhost user=nomad_services password=secure_password dbname=nomad_services port=5432 sslmode=disable TimeZone=UTC"
```

## File Structure

```
nomad-environment/
├── docker-compose.postgres.yml    # PostgreSQL Docker Compose configuration
├── .env.postgres                  # Environment variables
├── setup-postgresql.sh            # Standalone container setup script
├── start-postgres.sh              # Docker Compose management script
├── backup-postgresql.sh           # Database backup script (auto-generated)
├── restore-postgresql.sh          # Database restore script (auto-generated)
├── init-scripts/                  # Database initialization scripts
│   └── 01-init-database.sql       # Initial database setup
├── data/
│   └── postgresql/                # Database data directory
└── backups/
    └── postgresql/                # Database backups directory
```

## Database Management

### Starting the Database

```bash
# Start PostgreSQL only
./start-postgres.sh start

# Start PostgreSQL with PgAdmin
./start-postgres.sh start-admin
```

### Stopping the Database

```bash
./start-postgres.sh stop
```

### Viewing Status

```bash
./start-postgres.sh status
```

### Viewing Logs

```bash
./start-postgres.sh logs
```

### Connecting to Database

```bash
# Using the script
./start-postgres.sh connect

# Using psql directly
docker exec -it nomad-services-postgres psql -U nomad_services -d nomad_services

# Using connection string
psql "postgresql://nomad_services:secure_password@localhost:5432/nomad_services"
```

## Backup and Restore

### Creating Backups

```bash
# Create backup using the script
./start-postgres.sh backup

# Create backup manually
./backup-postgresql.sh

# Manual backup
docker exec nomad-services-postgres pg_dump -U nomad_services -d nomad_services > backup.sql
```

### Restoring from Backup

```bash
# Restore from backup
./restore-postgresql.sh /path/to/backup.sql

# List available backups
ls -la ./backups/postgresql/
```

## PgAdmin Interface

When started with the `start-admin` command, PgAdmin will be available at:

- **URL**: http://localhost:5050
- **Email**: admin@nomadservices.local
- **Password**: admin

### Connecting to Database in PgAdmin

1. Open PgAdmin at http://localhost:5050
2. Login with the credentials above
3. Add a new server with these settings:
   - **Name**: Nomad Services DB
   - **Host**: postgres
   - **Port**: 5432
   - **Username**: nomad_services
   - **Password**: secure_password

## Security Considerations

### For Development

The current configuration is optimized for development with:
- Default passwords (change in production)
- SSL disabled for local development
- Permissive network settings

### For Production

For production deployment, consider:

1. **Change default passwords**:
   ```bash
   # Update .env.postgres with secure passwords
   POSTGRES_PASSWORD=your_secure_password
   PGADMIN_PASSWORD=your_admin_password
   ```

2. **Enable SSL**:
   ```bash
   DB_SSL_MODE=require
   ```

3. **Network security**:
   - Use internal Docker networks
   - Restrict port exposure
   - Configure firewall rules

4. **Backup encryption**:
   - Encrypt backup files
   - Use secure backup storage

## Troubleshooting

### Common Issues

1. **Port already in use**:
   ```bash
   # Check what's using port 5432
   lsof -i :5432
   
   # Change port in .env.postgres
   POSTGRES_PORT=5433
   ```

2. **Permission errors**:
   ```bash
   # Fix data directory permissions
   sudo chown -R $(id -u):$(id -g) ./data/postgresql
   ```

3. **Database won't start**:
   ```bash
   # Check logs
   ./start-postgres.sh logs
   
   # Remove container and start fresh
   docker stop nomad-services-postgres
   docker rm nomad-services-postgres
   ./start-postgres.sh start
   ```

4. **Connection refused**:
   ```bash
   # Check if container is running
   docker ps | grep postgres
   
   # Check if PostgreSQL is ready
   docker exec nomad-services-postgres pg_isready -U nomad_services
   ```

### Reset Database

To completely reset the database:

```bash
# Stop and remove container
./start-postgres.sh stop
docker rm nomad-services-postgres

# Remove data directory
rm -rf ./data/postgresql

# Start fresh
./start-postgres.sh start
```

## Integration with Backend API

### Environment Variables

Set these environment variables when running the backend API:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=nomad_services
export DB_PASSWORD=secure_password
export DB_NAME=nomad_services
export DB_SSL_MODE=disable
```

### Running Backend with PostgreSQL

```bash
# Start PostgreSQL
./start-postgres.sh start

# Start backend API (from backend directory)
cd backend
go run main.go
```

## Performance Tuning

### Connection Pool Settings

The backend API uses these connection pool settings:

```go
sqlDB.SetMaxIdleConns(10)
sqlDB.SetMaxOpenConns(100)
sqlDB.SetConnMaxLifetime(time.Hour)
```

### PostgreSQL Configuration

For better performance, consider tuning these PostgreSQL settings:

```sql
-- In postgresql.conf
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
random_page_cost = 1.1
```

## Monitoring

### Health Checks

The setup includes built-in health checks:

```bash
# Check database health
./start-postgres.sh status

# Manual health check
docker exec nomad-services-postgres pg_isready -U nomad_services
```

### Database Size Monitoring

```sql
-- Check database size
SELECT get_database_size();

-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Support

For issues or questions about the PostgreSQL setup:

1. Check the troubleshooting section above
2. Review the logs: `./start-postgres.sh logs`
3. Check the official PostgreSQL documentation
4. Verify Docker and Docker Compose are properly installed

## Commands Reference

```bash
# PostgreSQL Management
./start-postgres.sh start          # Start PostgreSQL
./start-postgres.sh start-admin    # Start with PgAdmin
./start-postgres.sh stop           # Stop PostgreSQL
./start-postgres.sh restart        # Restart PostgreSQL
./start-postgres.sh logs           # Show logs
./start-postgres.sh connect        # Connect to database
./start-postgres.sh status         # Show status
./start-postgres.sh backup         # Create backup
./start-postgres.sh info           # Show connection info
./start-postgres.sh help           # Show help

# Standalone Container Management
./setup-postgresql.sh              # Setup container
./setup-postgresql.sh stop         # Stop container
./setup-postgresql.sh start        # Start container
./setup-postgresql.sh restart      # Restart container
./setup-postgresql.sh logs         # Show logs
./setup-postgresql.sh connect      # Connect to database
./setup-postgresql.sh status       # Show status
./setup-postgresql.sh remove       # Remove container

# Backup and Restore
./backup-postgresql.sh             # Create backup
./restore-postgresql.sh backup.sql # Restore from backup
```
