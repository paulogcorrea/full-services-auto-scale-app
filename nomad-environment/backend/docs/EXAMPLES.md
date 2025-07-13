# API Usage Examples

This document provides practical examples of how to use the Nomad Services API.

## Authentication Examples

### User Registration

```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "email": "admin@example.com",
    "password": "securepassword123",
    "first_name": "Admin",
    "last_name": "User"
  }'
```

Response:
```json
{
  "message": "User registered successfully",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "admin",
    "email": "admin@example.com",
    "first_name": "Admin",
    "last_name": "User",
    "role": "user",
    "is_active": true,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

### User Login

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "securepassword123"
  }'
```

Response:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "admin",
    "email": "admin@example.com",
    "role": "user",
    "is_active": true
  },
  "expires_at": "2024-01-02T00:00:00Z"
}
```

### Token Refresh

```bash
curl -X POST http://localhost:8080/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }'
```

## Service Management Examples

### Create a PostgreSQL Service

```bash
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X POST http://localhost:8080/api/v1/services \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "postgres-db",
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
  }'
```

### Create a Redis Service

```bash
curl -X POST http://localhost:8080/api/v1/services \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "redis-cache",
    "type": "database",
    "description": "Redis cache service",
    "config": {
      "image": "redis:7-alpine",
      "ports": [6379],
      "environment": {
        "REDIS_PASSWORD": "myredispassword"
      },
      "resources": {
        "cpu": 250,
        "memory": 512,
        "disk": 1024
      },
      "nomad_job_file": "redis.nomad"
    }
  }'
```

### Create a Node.js Web Server

```bash
curl -X POST http://localhost:8080/api/v1/services \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "api-server",
    "type": "web_server",
    "description": "Node.js API server",
    "config": {
      "image": "node:18-alpine",
      "ports": [3000],
      "environment": {
        "NODE_ENV": "production",
        "PORT": "3000",
        "DATABASE_URL": "postgresql://myuser:mypassword@postgres-db:5432/mydb"
      },
      "resources": {
        "cpu": 1000,
        "memory": 2048,
        "disk": 4096
      },
      "nomad_job_file": "nodejs.nomad",
      "custom_variables": {
        "APP_NAME": "my-api"
      }
    }
  }'
```

### List All Services

```bash
curl -X GET http://localhost:8080/api/v1/services \
  -H "Authorization: Bearer $TOKEN"
```

Response:
```json
{
  "services": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440000",
      "name": "postgres-db",
      "type": "database",
      "status": "stopped",
      "description": "PostgreSQL database for my application",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": "880e8400-e29b-41d4-a716-446655440000",
      "name": "redis-cache",
      "type": "database",
      "status": "stopped",
      "description": "Redis cache service",
      "created_at": "2024-01-01T00:10:00Z",
      "updated_at": "2024-01-01T00:10:00Z"
    }
  ],
  "total": 2
}
```

### Start a Service

```bash
SERVICE_ID="770e8400-e29b-41d4-a716-446655440000"

curl -X POST http://localhost:8080/api/v1/services/$SERVICE_ID/start \
  -H "Authorization: Bearer $TOKEN"
```

Response:
```json
{
  "message": "Service deployment started",
  "deployment": {
    "id": "990e8400-e29b-41d4-a716-446655440000",
    "service_id": "770e8400-e29b-41d4-a716-446655440000",
    "status": "pending",
    "nomad_job_id": "tenant-postgres-1704067200",
    "deployed_by": "550e8400-e29b-41d4-a716-446655440000",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

### Get Service Details

```bash
curl -X GET http://localhost:8080/api/v1/services/$SERVICE_ID \
  -H "Authorization: Bearer $TOKEN"
```

### Stop a Service

```bash
curl -X POST http://localhost:8080/api/v1/services/$SERVICE_ID/stop \
  -H "Authorization: Bearer $TOKEN"
```

### Restart a Service

```bash
curl -X POST http://localhost:8080/api/v1/services/$SERVICE_ID/restart \
  -H "Authorization: Bearer $TOKEN"
```

### Get Service Logs

```bash
curl -X GET http://localhost:8080/api/v1/services/$SERVICE_ID/logs \
  -H "Authorization: Bearer $TOKEN"
```

Response:
```json
{
  "logs": [
    "2024-01-01T00:00:00Z INFO: Starting PostgreSQL",
    "2024-01-01T00:00:01Z INFO: Database initialized",
    "2024-01-01T00:00:02Z INFO: Ready to accept connections"
  ]
}
```

### Get Service Metrics

```bash
curl -X GET http://localhost:8080/api/v1/services/$SERVICE_ID/metrics \
  -H "Authorization: Bearer $TOKEN"
```

Response:
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

## User Management Examples

### Get Current User Info

```bash
curl -X GET http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN"
```

### Update User Profile

```bash
curl -X PUT http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Smith",
    "email": "john.smith@example.com"
  }'
```

## Admin Examples

### List All Users (Admin Only)

```bash
curl -X GET "http://localhost:8080/api/v1/admin/users?limit=20&offset=0" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Update User Role (Admin Only)

```bash
USER_ID="550e8400-e29b-41d4-a716-446655440000"

curl -X PUT http://localhost:8080/api/v1/admin/users/$USER_ID/role \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "role": "tenant_admin"
  }'
```

### Deactivate User (Admin Only)

```bash
curl -X PUT http://localhost:8080/api/v1/admin/users/$USER_ID/deactivate \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Activate User (Admin Only)

```bash
curl -X PUT http://localhost:8080/api/v1/admin/users/$USER_ID/activate \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

## JavaScript/TypeScript Examples

### Using Fetch API

```javascript
class NomadServicesAPI {
  constructor(baseURL, token) {
    this.baseURL = baseURL;
    this.token = token;
  }

  async request(endpoint, options = {}) {
    const url = `${this.baseURL}/api/v1${endpoint}`;
    const config = {
      headers: {
        'Content-Type': 'application/json',
        ...(this.token && { Authorization: `Bearer ${this.token}` })
      },
      ...options
    };

    const response = await fetch(url, config);
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Request failed');
    }

    return response.json();
  }

  // Authentication
  async login(username, password) {
    const response = await this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ username, password })
    });
    
    this.token = response.token;
    return response;
  }

  async register(userData) {
    return this.request('/auth/register', {
      method: 'POST',
      body: JSON.stringify(userData)
    });
  }

  // Services
  async createService(serviceData) {
    return this.request('/services', {
      method: 'POST',
      body: JSON.stringify(serviceData)
    });
  }

  async listServices() {
    return this.request('/services');
  }

  async getService(serviceId) {
    return this.request(`/services/${serviceId}`);
  }

  async startService(serviceId) {
    return this.request(`/services/${serviceId}/start`, {
      method: 'POST'
    });
  }

  async stopService(serviceId) {
    return this.request(`/services/${serviceId}/stop`, {
      method: 'POST'
    });
  }

  async getServiceLogs(serviceId) {
    return this.request(`/services/${serviceId}/logs`);
  }

  async getServiceMetrics(serviceId) {
    return this.request(`/services/${serviceId}/metrics`);
  }
}

// Usage example
const api = new NomadServicesAPI('http://localhost:8080');

async function example() {
  try {
    // Login
    const loginResponse = await api.login('admin', 'password');
    console.log('Logged in:', loginResponse.user);

    // Create a service
    const service = await api.createService({
      name: 'my-database',
      type: 'database',
      description: 'PostgreSQL database',
      config: {
        image: 'postgres:13',
        ports: [5432],
        environment: {
          POSTGRES_USER: 'myuser',
          POSTGRES_PASSWORD: 'mypassword',
          POSTGRES_DB: 'mydb'
        },
        resources: {
          cpu: 500,
          memory: 1024,
          disk: 2048
        },
        nomad_job_file: 'postgresql.nomad'
      }
    });
    console.log('Service created:', service);

    // Start the service
    const deployment = await api.startService(service.id);
    console.log('Service started:', deployment);

    // Get service logs
    const logs = await api.getServiceLogs(service.id);
    console.log('Service logs:', logs);

  } catch (error) {
    console.error('Error:', error.message);
  }
}
```

### Using Axios

```javascript
import axios from 'axios';

class NomadServicesClient {
  constructor(baseURL) {
    this.client = axios.create({
      baseURL: `${baseURL}/api/v1`,
      headers: {
        'Content-Type': 'application/json'
      }
    });

    // Request interceptor to add token
    this.client.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor for error handling
    this.client.interceptors.response.use(
      (response) => response.data,
      (error) => {
        if (error.response?.status === 401) {
          localStorage.removeItem('token');
          // Redirect to login
        }
        return Promise.reject(error.response?.data || error);
      }
    );
  }

  // Auth methods
  async login(credentials) {
    const response = await this.client.post('/auth/login', credentials);
    localStorage.setItem('token', response.token);
    return response;
  }

  async logout() {
    localStorage.removeItem('token');
  }

  // Service methods
  async getServices() {
    return this.client.get('/services');
  }

  async createService(serviceData) {
    return this.client.post('/services', serviceData);
  }

  async startService(serviceId) {
    return this.client.post(`/services/${serviceId}/start`);
  }

  async stopService(serviceId) {
    return this.client.post(`/services/${serviceId}/stop`);
  }
}
```

## Python Examples

### Using Requests

```python
import requests
import json

class NomadServicesAPI:
    def __init__(self, base_url):
        self.base_url = base_url
        self.token = None
        self.session = requests.Session()
        
    def _headers(self):
        headers = {'Content-Type': 'application/json'}
        if self.token:
            headers['Authorization'] = f'Bearer {self.token}'
        return headers
    
    def _request(self, method, endpoint, **kwargs):
        url = f"{self.base_url}/api/v1{endpoint}"
        response = self.session.request(
            method, url, 
            headers=self._headers(),
            **kwargs
        )
        response.raise_for_status()
        return response.json()
    
    def login(self, username, password):
        data = {'username': username, 'password': password}
        response = self._request('POST', '/auth/login', json=data)
        self.token = response['token']
        return response
    
    def create_service(self, service_data):
        return self._request('POST', '/services', json=service_data)
    
    def list_services(self):
        return self._request('GET', '/services')
    
    def start_service(self, service_id):
        return self._request('POST', f'/services/{service_id}/start')
    
    def stop_service(self, service_id):
        return self._request('POST', f'/services/{service_id}/stop')
    
    def get_service_logs(self, service_id):
        return self._request('GET', f'/services/{service_id}/logs')

# Usage example
api = NomadServicesAPI('http://localhost:8080')

# Login
api.login('admin', 'password')

# Create a service
service = api.create_service({
    'name': 'postgres-db',
    'type': 'database',
    'description': 'PostgreSQL database',
    'config': {
        'image': 'postgres:13',
        'ports': [5432],
        'environment': {
            'POSTGRES_USER': 'myuser',
            'POSTGRES_PASSWORD': 'mypassword',
            'POSTGRES_DB': 'mydb'
        },
        'resources': {
            'cpu': 500,
            'memory': 1024,
            'disk': 2048
        },
        'nomad_job_file': 'postgresql.nomad'
    }
})

print(f"Created service: {service['id']}")

# Start the service
deployment = api.start_service(service['id'])
print(f"Started deployment: {deployment['deployment']['id']}")
```

## Health Check Example

```bash
# Simple health check
curl -X GET http://localhost:8080/health

# Response
{
  "status": "healthy",
  "version": "1.0.0"
}
```

## Error Handling Examples

### Common Error Responses

#### 400 Bad Request
```json
{
  "error": "Service 'postgres-db' of type 'database' already exists for this tenant"
}
```

#### 401 Unauthorized
```json
{
  "error": "Invalid token"
}
```

#### 403 Forbidden
```json
{
  "error": "Admin access required"
}
```

#### 404 Not Found
```json
{
  "error": "Service not found"
}
```

#### 500 Internal Server Error
```json
{
  "error": "Failed to connect to Nomad cluster"
}
```

## Testing with Postman

### Environment Variables
Set up these environment variables in Postman:

- `BASE_URL`: `http://localhost:8080`
- `TOKEN`: Set this after login

### Collection Structure
1. **Auth**
   - Register User
   - Login User
   - Refresh Token

2. **Services**
   - Create Service
   - List Services
   - Get Service
   - Start Service
   - Stop Service
   - Get Logs
   - Get Metrics

3. **Admin**
   - List Users
   - Update User Role

### Pre-request Script for Authentication
```javascript
// Add this to requests that need authentication
if (pm.environment.get("TOKEN")) {
    pm.request.headers.add({
        key: "Authorization",
        value: "Bearer " + pm.environment.get("TOKEN")
    });
}
```

### Test Script for Login
```javascript
// Add this to the Login request
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has token", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('token');
    pm.environment.set("TOKEN", jsonData.token);
});
```

This concludes the comprehensive documentation for the Nomad Services API. The API is now fully documented and ready for development and production use.
