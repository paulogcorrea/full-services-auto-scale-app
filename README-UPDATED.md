# Nomad Services Platform - Updated Structure

## Current Folder Structure

```
full-services-auto-scale-app/
├── backend/                    # Backend Go API (moved from nomad-environment/)
│   ├── .env                   # Backend environment configuration
│   ├── go.mod                 # Go dependencies
│   ├── main.go                # Main backend application
│   └── internal/              # Internal Go packages
├── frontend/                   # Frontend Angular app (moved from nomad-environment/)
│   ├── package.json           # npm dependencies
│   ├── src/                   # Angular source code
│   └── node_modules/          # npm packages
├── init-scripts/              # PostgreSQL and initialization scripts
│   ├── setup-postgresql.sh    # PostgreSQL Docker setup
│   ├── start-nomad-environment.sh  # Nomad environment manager
│   └── start-postgres.sh      # PostgreSQL startup script
├── nomad-environment/         # Nomad, Consul, and job definitions
│   ├── configs/               # Nomad configuration files
│   ├── jobs/                  # Nomad job definitions
│   ├── scripts/               # Utility scripts
│   ├── logs/                  # Log files
│   └── volumes/               # Docker volumes
├── .env.postgres              # PostgreSQL environment variables
├── docker-compose.postgres.yml # PostgreSQL Docker Compose
├── README-PostgreSQL.md       # PostgreSQL documentation
├── start-platform.sh          # Main platform startup script
└── stop-platform.sh           # Main platform stop script
```

## Quick Start

### 1. Start the Full Platform

Run this command from the root directory:

```bash
./start-platform.sh
```

This will start:
- PostgreSQL (Docker container)
- Consul (service discovery)
- Nomad (orchestration)
- Backend API (Go application)
- Frontend (Angular application)

### 2. Stop the Platform

```bash
./stop-platform.sh
```

### 3. Individual Service Management

#### PostgreSQL Only
```bash
./init-scripts/setup-postgresql.sh start
./init-scripts/setup-postgresql.sh stop
./init-scripts/setup-postgresql.sh status
```

#### Nomad Environment Manager
```bash
./init-scripts/start-nomad-environment.sh
```

This provides an interactive menu to:
- Deploy various services (Prometheus, Grafana, MySQL, etc.)
- Manage running services
- Stop specific services

## Service Access

Once the platform is running, you can access:

- **Frontend**: http://localhost:4200
- **Backend API**: http://localhost:8080
- **Nomad UI**: http://localhost:4646
- **Consul UI**: http://localhost:8500
- **PostgreSQL**: localhost:5432

## Key Changes Made

1. **Moved Components**: 
   - `backend/` moved to root level
   - `frontend/` moved to root level
   - PostgreSQL scripts moved to `init-scripts/`

2. **Updated Scripts**:
   - All startup scripts updated for new paths
   - Docker Compose files updated
   - Environment configurations updated

3. **New Master Scripts**:
   - `start-platform.sh` - Start everything
   - `stop-platform.sh` - Stop everything

## Database Configuration

The platform uses PostgreSQL with these credentials:
- **Host**: localhost:5432
- **Database**: nomad_services
- **Username**: nomad_services
- **Password**: secure_password

## Development

### Backend Development
```bash
cd backend
go run main.go
```

### Frontend Development
```bash
cd frontend
npm install
npm start
```

## Troubleshooting

1. **Port Conflicts**: Check if ports 4200, 8080, 4646, 8500, or 5432 are in use
2. **Docker Issues**: Ensure Docker is running for PostgreSQL
3. **Go Dependencies**: Run `go mod tidy` in the backend directory
4. **Node Dependencies**: Run `npm install` in the frontend directory

## Architecture

The platform follows a microservices architecture:
- **Frontend**: Angular SPA
- **Backend**: Go REST API
- **Database**: PostgreSQL
- **Orchestration**: Nomad
- **Service Discovery**: Consul
- **Containerization**: Docker

All services are designed to work together seamlessly while maintaining individual development capabilities.
