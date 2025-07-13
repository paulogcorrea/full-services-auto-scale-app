# Nomad Services API Documentation

## Overview

The Nomad Services API is a comprehensive backend service built in Go that provides a SaaS platform for managing and deploying services using HashiCorp Nomad. The API enforces a **one instance per service type per tenant** constraint, making it ideal for development environments and controlled deployments.

## Key Features

- **Multi-tenant Architecture**: Support for multiple tenants with isolated service management
- **Service Lifecycle Management**: Create, start, stop, restart, and monitor services
- **Authentication & Authorization**: JWT-based authentication with role-based access control
- **Nomad Integration**: Direct integration with HashiCorp Nomad for container orchestration
- **Real-time Monitoring**: Service logs and metrics collection
- **RESTful API**: Clean, well-structured REST endpoints
- **Database Integration**: PostgreSQL with GORM for data persistence

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Go Backend    │    │   Nomad         │
│   (Angular)     │◄──►│   API Server    │◄──►│   Cluster       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   PostgreSQL    │
                       │   Database      │
                       └─────────────────┘
```

## Technology Stack

- **Language**: Go 1.21+
- **Web Framework**: Gin
- **Database**: PostgreSQL with GORM
- **Authentication**: JWT tokens
- **Orchestration**: HashiCorp Nomad
- **Logging**: Logrus
- **Configuration**: Environment variables

## Quick Start

### Prerequisites

- Go 1.21 or higher
- PostgreSQL database
- HashiCorp Nomad cluster (running locally or remotely)
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd nomad-environment/backend
```

2. Install dependencies:
```bash
go mod tidy
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Run database migrations:
```bash
go run main.go migrate
```

5. Start the server:
```bash
go run main.go
```

The API will be available at `http://localhost:8080`

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SERVER_PORT` | Server port | `8080` |
| `ENVIRONMENT` | Environment (development/production) | `development` |
| `LOG_LEVEL` | Log level (debug/info/warn/error) | `info` |
| `DB_HOST` | Database host | `localhost` |
| `DB_PORT` | Database port | `5432` |
| `DB_USER` | Database user | `postgres` |
| `DB_PASSWORD` | Database password | `postgres` |
| `DB_NAME` | Database name | `nomad_services` |
| `JWT_SECRET` | JWT secret key | `change-in-production` |
| `NOMAD_ADDR` | Nomad server address | `http://127.0.0.1:4646` |
| `NOMAD_JOBS_PATH` | Path to Nomad job files | `../jobs` |

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/refresh` - Refresh JWT token

### Users
- `GET /api/v1/users/me` - Get current user
- `PUT /api/v1/users/me` - Update current user

### Services
- `POST /api/v1/services` - Create a new service
- `GET /api/v1/services` - List all services
- `GET /api/v1/services/:id` - Get service details
- `PUT /api/v1/services/:id` - Update service
- `DELETE /api/v1/services/:id` - Delete service
- `POST /api/v1/services/:id/start` - Start service
- `POST /api/v1/services/:id/stop` - Stop service
- `POST /api/v1/services/:id/restart` - Restart service
- `GET /api/v1/services/:id/logs` - Get service logs
- `GET /api/v1/services/:id/metrics` - Get service metrics

### Templates
- `GET /api/v1/templates` - List service templates
- `GET /api/v1/templates/:id` - Get template details

### Admin (Admin role required)
- `GET /api/v1/admin/users` - List all users
- `PUT /api/v1/admin/users/:id/role` - Update user role
- `PUT /api/v1/admin/users/:id/activate` - Activate user
- `PUT /api/v1/admin/users/:id/deactivate` - Deactivate user

### Health Check
- `GET /health` - Health check endpoint

## Service Types

The API supports the following service types:

- **database**: MySQL, PostgreSQL, MongoDB, Redis
- **web_server**: Nginx, Apache, Node.js, PHP
- **message_queue**: Kafka, RabbitMQ
- **monitoring**: Prometheus, Grafana, Loki
- **devops**: Jenkins, Nexus, SonarQube
- **custom**: Custom services

## Service Constraints

- **One Instance Policy**: Each tenant can only have one instance of each service type
- **Tenant Isolation**: Services are isolated per tenant
- **Resource Limits**: Configurable resource limits per service
- **Service Limits**: Maximum number of services per tenant based on plan

## Error Handling

The API uses standard HTTP status codes and returns JSON error responses:

```json
{
  "error": "Error message description"
}
```

Common status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

## Rate Limiting

Currently, no rate limiting is implemented, but it's recommended for production deployments.

## Security

- JWT tokens for authentication
- Password hashing with bcrypt
- CORS configuration
- Input validation and sanitization
- SQL injection prevention through GORM

## Development

### Project Structure

```
backend/
├── cmd/                    # Application entrypoints
├── internal/
│   ├── api/               # HTTP handlers and middleware
│   ├── config/            # Configuration management
│   ├── database/          # Database connection and migrations
│   ├── models/            # Data models
│   └── services/          # Business logic
├── docs/                  # Documentation
├── go.mod                 # Go module file
└── main.go               # Main application file
```

### Running Tests

```bash
go test ./...
```

### Building for Production

```bash
go build -o nomad-services-api main.go
```

## Deployment

### Docker Deployment

```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o nomad-services-api main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/nomad-services-api .
CMD ["./nomad-services-api"]
```

### Kubernetes Deployment

Refer to the `k8s/` directory for Kubernetes deployment manifests.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support, please open an issue in the repository or contact the development team.
