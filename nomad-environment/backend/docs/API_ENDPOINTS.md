# API Endpoints Documentation

## Base URL

All API endpoints are prefixed with `/api/v1` unless otherwise specified.

## Authentication

Most endpoints require authentication via JWT token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

## Content Type

All requests and responses use JSON format:

```
Content-Type: application/json
```

---

## Authentication Endpoints

### POST /auth/register

Register a new user account.

**Request Body:**
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "securepassword123",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Response:** `201 Created`
```json
{
  "message": "User registered successfully",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "john_doe",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "user",
    "is_active": true,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

**Error Responses:**
- `400 Bad Request` - Invalid input data
- `400 Bad Request` - Username or email already exists

---

### POST /auth/login

Authenticate user and receive JWT tokens.

**Request Body:**
```json
{
  "username": "john_doe",
  "password": "securepassword123"
}
```

**Response:** `200 OK`
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "john_doe",
    "email": "john@example.com",
    "role": "user",
    "is_active": true
  },
  "expires_at": "2024-01-02T00:00:00Z"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid input data
- `401 Unauthorized` - Invalid credentials
- `401 Unauthorized` - Account is inactive

---

### POST /auth/refresh

Refresh JWT token using refresh token.

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:** `200 OK`
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "john_doe",
    "email": "john@example.com",
    "role": "user"
  },
  "expires_at": "2024-01-02T00:00:00Z"
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid refresh token
- `401 Unauthorized` - Account is inactive

---

## User Endpoints

### GET /users/me

Get current user information.

**Headers:** `Authorization: Bearer <jwt_token>`

**Response:** `200 OK`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "john_doe",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "role": "user",
  "is_active": true,
  "tenant_id": "660e8400-e29b-41d4-a716-446655440000",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or missing token

---

### PUT /users/me

Update current user information.

**Headers:** `Authorization: Bearer <jwt_token>`

**Request Body:**
```json
{
  "first_name": "John",
  "last_name": "Smith",
  "email": "john.smith@example.com"
}
```

**Response:** `200 OK`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "john_doe",
  "email": "john.smith@example.com",
  "first_name": "John",
  "last_name": "Smith",
  "role": "user",
  "is_active": true,
  "updated_at": "2024-01-01T01:00:00Z"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid input data
- `401 Unauthorized` - Invalid or missing token
- `500 Internal Server Error` - Failed to update user

---

## Service Endpoints

### POST /services

Create a new service. Only one instance per service type per tenant is allowed.

**Headers:** `Authorization: Bearer <jwt_token>`

**Request Body:**
```json
{
  "name": "my-postgres-db",
  "type": "database",
  "description": "PostgreSQL database for my application",
  "config": {
    "image": "postgres:13",
    "ports": [5432],
    "environment": {
      "POSTGRES_USER": "myuser",
      "POSTGRES_PASSWORD": "mypassword",
      "POSTGRES_DB": "mydb"
    },
    "resources": {
      "cpu": 500,
      "memory": 1024,
      "disk": 2048
    },
    "nomad_job_file": "postgresql.nomad",
    "custom_variables": {
      "DB_NAME": "mydb"
    }
  }
}
```

**Response:** `201 Created`
```json
{
  "id": "770e8400-e29b-41d4-a716-446655440000",
  "name": "my-postgres-db",
  "type": "database",
  "status": "stopped",
  "description": "PostgreSQL database for my application",
  "config": {
    "image": "postgres:13",
    "ports": [5432],
    "environment": {
      "POSTGRES_USER": "myuser",
      "POSTGRES_PASSWORD": "mypassword",
      "POSTGRES_DB": "mydb"
    },
    "resources": {
      "cpu": 500,
      "memory": 1024,
      "disk": 2048
    },
    "nomad_job_file": "postgresql.nomad",
    "custom_variables": {
      "DB_NAME": "mydb"
    }
  },
  "created_by": "550e8400-e29b-41d4-a716-446655440000",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid input data
- `400 Bad Request` - Service already exists for this tenant
- `400 Bad Request` - Tenant has reached maximum number of services
- `401 Unauthorized` - Invalid or missing token

---

### GET /services

List all services for the current tenant.

**Headers:** `Authorization: Bearer <jwt_token>`

**Response:** `200 OK`
```json
{
  "services": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440000",
      "name": "my-postgres-db",
      "type": "database",
      "status": "running",
      "description": "PostgreSQL database for my application",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z",
      "deployments": [
        {
          "id": "880e8400-e29b-41d4-a716-446655440000",
          "status": "completed",
          "nomad_job_id": "tenant-postgres-1704067200",
          "started_at": "2024-01-01T00:00:00Z",
          "completed_at": "2024-01-01T00:01:00Z"
        }
      ]
    }
  ],
  "total": 1
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or missing token
- `500 Internal Server Error` - Failed to list services

---

### GET /services/:id

Get details of a specific service.

**Headers:** `Authorization: Bearer <jwt_token>`

**Parameters:**
- `id` (UUID) - Service ID

**Response:** `200 OK`
```json
{
  "id": "770e8400-e29b-41d4-a716-446655440000",
  "name": "my-postgres-db",
  "type": "database",
  "status": "running",
  "description": "PostgreSQL database for my application",
  "config": {
    "image": "postgres:13",
    "ports": [5432],
    "environment": {
      "POSTGRES_USER": "myuser",
      "POSTGRES_PASSWORD": "mypassword",
      "POSTGRES_DB": "mydb"
    },
    "resources": {
      "cpu": 500,
      "memory": 1024,
      "disk": 2048
    },
    "nomad_job_file": "postgresql.nomad"
  },
  "created_by": "550e8400-e29b-41d4-a716-446655440000",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid service ID
- `401 Unauthorized` - Invalid or missing token
- `404 Not Found` - Service not found

---

### PUT /services/:id

Update a service configuration.

**Headers:** `Authorization: Bearer <jwt_token>`

**Parameters:**
- `id` (UUID) - Service ID

**Request Body:**
```json
{
  "name": "my-updated-postgres-db",
  "type": "database",
  "description": "Updated PostgreSQL database",
  "config": {
    "image": "postgres:14",
    "ports": [5432],
    "environment": {
      "POSTGRES_USER": "myuser",
      "POSTGRES_PASSWORD": "newpassword",
      "POSTGRES_DB": "mydb"
    },
    "resources": {
      "cpu": 1000,
      "memory": 2048,
      "disk": 4096
    },
    "nomad_job_file": "postgresql.nomad"
  }
}
```

**Response:** `200 OK`
```json
{
  "id": "770e8400-e29b-41d4-a716-446655440000",
  "name": "my-updated-postgres-db",
  "type": "database",
  "status": "running",
  "description": "Updated PostgreSQL database",
  "config": {
    "image": "postgres:14",
    "ports": [5432],
    "environment": {
      "POSTGRES_USER": "myuser",
      "POSTGRES_PASSWORD": "newpassword",
      "POSTGRES_DB": "mydb"
    },
    "resources": {
      "cpu": 1000,
      "memory": 2048,
      "disk": 4096
    },
    "nomad_job_file": "postgresql.nomad"
  },
  "updated_at": "2024-01-01T01:00:00Z"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid service ID or input data
- `401 Unauthorized` - Invalid or missing token
- `404 Not Found` - Service not found

---

### DELETE /services/:id

Delete a service.

**Headers:** `Authorization: Bearer <jwt_token>`

**Parameters:**
- `id` (UUID) - Service ID

**Response:** `200 OK`
```json
{
  "message": "Service deleted successfully"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid service ID
- `401 Unauthorized` - Invalid or missing token
- `404 Not Found` - Service not found

---

### POST /services/:id/start

Start a service deployment.

**Headers:** `Authorization: Bearer <jwt_token>`

**Parameters:**
- `id` (UUID) - Service ID

**Response:** `200 OK`
```json
{
  "message": "Service deployment started",
  "deployment": {
    "id": "880e8400-e29b-41d4-a716-446655440000",
    "service_id": "770e8400-e29b-41d4-a716-446655440000",
    "status": "pending",
    "nomad_job_id": "tenant-postgres-1704067200",
    "deployed_by": "550e8400-e29b-41d4-a716-446655440000",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

**Error Responses:**
- `400 Bad Request` - Invalid service ID
- `400 Bad Request` - Service is already running
- `400 Bad Request` - Service deployment already in progress
- `401 Unauthorized` - Invalid or missing token

---

### POST /services/:id/stop

Stop a running service.

**Headers:** `Authorization: Bearer <jwt_token>`

**Parameters:**
- `id` (UUID) - Service ID

**Response:** `200 OK`
```json
{
  "message": "Service stopped successfully"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid service ID
- `400 Bad Request` - Service is not running
- `401 Unauthorized` - Invalid or missing token

---

### POST /services/:id/restart

Restart a running service.

**Headers:** `Authorization: Bearer <jwt_token>`

**Parameters:**
- `id` (UUID) - Service ID

**Response:** `200 OK`
```json
{
  "message": "Service restarted successfully"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid service ID
- `400 Bad Request` - Service is not running
- `401 Unauthorized` - Invalid or missing token

---

### GET /services/:id/logs

Get logs for a service.

**Headers:** `Authorization: Bearer <jwt_token>`

**Parameters:**
- `id` (UUID) - Service ID

**Response:** `200 OK`
```json
{
  "logs": [
    "2024-01-01T00:00:00Z INFO: Starting PostgreSQL",
    "2024-01-01T00:00:01Z INFO: Database initialized",
    "2024-01-01T00:00:02Z INFO: Ready to accept connections"
  ]
}
```

**Error Responses:**
- `400 Bad Request` - Invalid service ID
- `401 Unauthorized` - Invalid or missing token
- `500 Internal Server Error` - Failed to get logs

---

### GET /services/:id/metrics

Get metrics for a service.

**Headers:** `Authorization: Bearer <jwt_token>`

**Parameters:**
- `id` (UUID) - Service ID

**Response:** `200 OK`
```json
{
  "metrics": {
    "cpu_usage": 45.2,
    "memory_usage": 536870912,
    "allocation_id": "12345678-1234-1234-1234-123456789012",
    "allocation_status": "running",
    "node_id": "87654321-4321-4321-4321-210987654321"
  }
}
```

**Error Responses:**
- `400 Bad Request` - Invalid service ID
- `401 Unauthorized` - Invalid or missing token
- `500 Internal Server Error` - Failed to get metrics

---

## Template Endpoints

### GET /templates

List available service templates.

**Headers:** `Authorization: Bearer <jwt_token>`

**Response:** `200 OK`
```json
{
  "templates": [
    {
      "id": "990e8400-e29b-41d4-a716-446655440000",
      "name": "postgresql",
      "type": "database",
      "description": "PostgreSQL database template",
      "icon": "database",
      "category": "Database",
      "tags": ["postgresql", "database", "sql"],
      "is_public": true,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 1
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or missing token

---

### GET /templates/:id

Get details of a specific template.

**Headers:** `Authorization: Bearer <jwt_token>`

**Parameters:**
- `id` (UUID) - Template ID

**Response:** `200 OK`
```json
{
  "id": "990e8400-e29b-41d4-a716-446655440000",
  "name": "postgresql",
  "type": "database",
  "description": "PostgreSQL database template",
  "icon": "database",
  "category": "Database",
  "tags": ["postgresql", "database", "sql"],
  "config": {
    "image": "postgres:13",
    "ports": [5432],
    "environment": {
      "POSTGRES_USER": "{{DB_USER}}",
      "POSTGRES_PASSWORD": "{{DB_PASSWORD}}",
      "POSTGRES_DB": "{{DB_NAME}}"
    },
    "resources": {
      "cpu": 500,
      "memory": 1024,
      "disk": 2048
    },
    "nomad_job_file": "postgresql.nomad"
  },
  "is_public": true,
  "created_at": "2024-01-01T00:00:00Z"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid template ID
- `401 Unauthorized` - Invalid or missing token
- `404 Not Found` - Template not found

---

## Admin Endpoints

All admin endpoints require the `admin` role.

### GET /admin/users

List all users (admin only).

**Headers:** `Authorization: Bearer <jwt_token>`

**Query Parameters:**
- `limit` (integer) - Maximum number of users to return (default: 10)
- `offset` (integer) - Number of users to skip (default: 0)

**Response:** `200 OK`
```json
{
  "users": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "username": "john_doe",
      "email": "john@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "role": "user",
      "is_active": true,
      "tenant_id": "660e8400-e29b-41d4-a716-446655440000",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 1,
  "limit": 10,
  "offset": 0
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or missing token
- `403 Forbidden` - Insufficient permissions
- `500 Internal Server Error` - Failed to list users

---

### PUT /admin/users/:id/role

Update user role (admin only).

**Headers:** `Authorization: Bearer <jwt_token>`

**Parameters:**
- `id` (UUID) - User ID

**Request Body:**
```json
{
  "role": "tenant_admin"
}
```

**Response:** `200 OK`
```json
{
  "message": "User role updated successfully"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid user ID or role
- `401 Unauthorized` - Invalid or missing token
- `403 Forbidden` - Insufficient permissions
- `500 Internal Server Error` - Failed to update user role

---

### PUT /admin/users/:id/activate

Activate a user account (admin only).

**Headers:** `Authorization: Bearer <jwt_token>`

**Parameters:**
- `id` (UUID) - User ID

**Response:** `200 OK`
```json
{
  "message": "User activated successfully"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid user ID
- `401 Unauthorized` - Invalid or missing token
- `403 Forbidden` - Insufficient permissions
- `500 Internal Server Error` - Failed to activate user

---

### PUT /admin/users/:id/deactivate

Deactivate a user account (admin only).

**Headers:** `Authorization: Bearer <jwt_token>`

**Parameters:**
- `id` (UUID) - User ID

**Response:** `200 OK`
```json
{
  "message": "User deactivated successfully"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid user ID
- `401 Unauthorized` - Invalid or missing token
- `403 Forbidden` - Insufficient permissions
- `500 Internal Server Error` - Failed to deactivate user

---

## Health Check Endpoint

### GET /health

Check API health status.

**Response:** `200 OK`
```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

This endpoint is always accessible and doesn't require authentication.
