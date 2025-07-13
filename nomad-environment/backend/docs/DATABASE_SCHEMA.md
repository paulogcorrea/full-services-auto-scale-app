# Database Schema Documentation

## Overview

The Nomad Services API uses PostgreSQL as its primary database with GORM as the ORM. This document describes the database schema, relationships, and constraints.

## Database Configuration

- **Database**: PostgreSQL 12+
- **ORM**: GORM v1.25+
- **Migrations**: Auto-migration on startup
- **Connection Pool**: 
  - Max Idle Connections: 10
  - Max Open Connections: 100
  - Connection Max Lifetime: 1 hour

## Tables

### users

Stores user account information.

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    role VARCHAR(50) DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    tenant_id UUID REFERENCES tenants(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Indexes:**
- `users_email_idx` - Unique index on email
- `users_username_idx` - Unique index on username
- `users_tenant_id_idx` - Index on tenant_id

**Constraints:**
- `role` must be one of: 'admin', 'user', 'tenant_admin'

---

### tenants

Stores tenant/organization information for multi-tenancy.

```sql
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    domain VARCHAR(255) UNIQUE,
    is_active BOOLEAN DEFAULT true,
    plan VARCHAR(50) DEFAULT 'free',
    max_services INTEGER DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Indexes:**
- `tenants_slug_idx` - Unique index on slug
- `tenants_domain_idx` - Unique index on domain

**Constraints:**
- `plan` must be one of: 'free', 'starter', 'pro', 'enterprise'

---

### services

Stores service definitions and configurations.

```sql
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'stopped',
    description TEXT,
    config JSONB,
    tenant_id UUID REFERENCES tenants(id),
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Indexes:**
- `services_tenant_id_idx` - Index on tenant_id
- `services_created_by_idx` - Index on created_by
- `services_type_idx` - Index on type
- `services_status_idx` - Index on status
- `services_name_tenant_unique` - Unique composite index on (name, tenant_id)

**Constraints:**
- `type` must be one of: 'database', 'web_server', 'message_queue', 'monitoring', 'devops', 'custom'
- `status` must be one of: 'running', 'stopped', 'error', 'pending'
- Only one service per (name, type, tenant_id) combination

---

### service_deployments

Stores deployment history and status for services.

```sql
CREATE TABLE service_deployments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending',
    nomad_job_id VARCHAR(255),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    error_msg TEXT,
    deployed_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Indexes:**
- `service_deployments_service_id_idx` - Index on service_id
- `service_deployments_deployed_by_idx` - Index on deployed_by
- `service_deployments_status_idx` - Index on status
- `service_deployments_nomad_job_id_idx` - Index on nomad_job_id

**Constraints:**
- `status` must be one of: 'pending', 'running', 'completed', 'failed'

---

### service_templates

Stores reusable service templates.

```sql
CREATE TABLE service_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    description TEXT,
    icon VARCHAR(255),
    category VARCHAR(255),
    tags TEXT[],
    config JSONB,
    is_public BOOLEAN DEFAULT true,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Indexes:**
- `service_templates_name_idx` - Index on name
- `service_templates_type_idx` - Index on type
- `service_templates_category_idx` - Index on category
- `service_templates_created_by_idx` - Index on created_by
- `service_templates_is_public_idx` - Index on is_public

**Constraints:**
- `type` must be one of: 'database', 'web_server', 'message_queue', 'monitoring', 'devops', 'custom'

---

### audit_logs

Stores audit trail for all user actions.

```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    tenant_id UUID REFERENCES tenants(id),
    action VARCHAR(255) NOT NULL,
    resource VARCHAR(255) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Indexes:**
- `audit_logs_user_id_idx` - Index on user_id
- `audit_logs_tenant_id_idx` - Index on tenant_id
- `audit_logs_action_idx` - Index on action
- `audit_logs_resource_idx` - Index on resource
- `audit_logs_created_at_idx` - Index on created_at

---

### api_keys

Stores API keys for programmatic access.

```sql
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    key VARCHAR(255) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id),
    tenant_id UUID REFERENCES tenants(id),
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP,
    last_used TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Indexes:**
- `api_keys_key_idx` - Unique index on key
- `api_keys_user_id_idx` - Index on user_id
- `api_keys_tenant_id_idx` - Index on tenant_id
- `api_keys_is_active_idx` - Index on is_active

---

### subscriptions

Stores subscription and billing information for tenants.

```sql
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    plan VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    price_per_month DECIMAL(10,2),
    max_services INTEGER,
    billing_cycle VARCHAR(50) DEFAULT 'monthly',
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    cancel_at_period_end BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Indexes:**
- `subscriptions_tenant_id_idx` - Index on tenant_id
- `subscriptions_plan_idx` - Index on plan
- `subscriptions_status_idx` - Index on status

**Constraints:**
- `plan` must be one of: 'free', 'starter', 'pro', 'enterprise'
- `status` must be one of: 'active', 'canceled', 'expired', 'pending'
- `billing_cycle` must be one of: 'monthly', 'yearly'

## Relationships

### User Relationships
- **User** belongs to **Tenant** (many-to-one)
- **User** has many **Services** (one-to-many, as creator)
- **User** has many **ServiceDeployments** (one-to-many, as deployer)
- **User** has many **ServiceTemplates** (one-to-many, as creator)
- **User** has many **AuditLogs** (one-to-many)
- **User** has many **ApiKeys** (one-to-many)

### Tenant Relationships
- **Tenant** has many **Users** (one-to-many)
- **Tenant** has many **Services** (one-to-many)
- **Tenant** has one **Subscription** (one-to-one)
- **Tenant** has many **AuditLogs** (one-to-many)
- **Tenant** has many **ApiKeys** (one-to-many)

### Service Relationships
- **Service** belongs to **Tenant** (many-to-one)
- **Service** belongs to **User** (many-to-one, as creator)
- **Service** has many **ServiceDeployments** (one-to-many)

### Other Relationships
- **ServiceDeployment** belongs to **Service** (many-to-one)
- **ServiceDeployment** belongs to **User** (many-to-one, as deployer)
- **ServiceTemplate** belongs to **User** (many-to-one, as creator)
- **Subscription** belongs to **Tenant** (many-to-one)
- **AuditLog** belongs to **User** (many-to-one)
- **AuditLog** belongs to **Tenant** (many-to-one)
- **ApiKey** belongs to **User** (many-to-one)
- **ApiKey** belongs to **Tenant** (many-to-one)

## JSONB Fields

### services.config

```json
{
  "image": "postgres:13",
  "ports": [5432],
  "environment": {
    "POSTGRES_USER": "myuser",
    "POSTGRES_PASSWORD": "mypassword",
    "POSTGRES_DB": "mydb"
  },
  "volumes": ["/data:/var/lib/postgresql/data"],
  "resources": {
    "cpu": 500,
    "memory": 1024,
    "disk": 2048
  },
  "health_check": {
    "enabled": true,
    "path": "/health",
    "interval": "30s",
    "timeout": "5s",
    "retries": 3
  },
  "nomad_job_file": "postgresql.nomad",
  "custom_variables": {
    "DB_NAME": "mydb",
    "DB_USER": "myuser"
  }
}
```

### service_templates.config

Similar structure to `services.config` but may contain template variables like `{{DB_USER}}`.

## Constraints and Business Rules

### Service Constraints
1. **One Instance Per Service Type**: Each tenant can only have one service of each type
2. **Service Name Uniqueness**: Service names must be unique within a tenant
3. **Resource Limits**: Services have configurable CPU, memory, and disk limits
4. **Tenant Service Limits**: Tenants have maximum service limits based on their plan

### User Constraints
1. **Unique Email**: Email addresses must be unique across all users
2. **Unique Username**: Usernames must be unique across all users
3. **Active Status**: Only active users can authenticate
4. **Role-Based Access**: Users can only access resources based on their role

### Tenant Constraints
1. **Unique Slug**: Tenant slugs must be unique
2. **Unique Domain**: Tenant domains must be unique
3. **Plan Limits**: Each plan has specific service and resource limits

## Migration Strategy

### Initial Migration
```sql
-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables in order (respecting foreign keys)
1. tenants
2. users
3. services
4. service_deployments
5. service_templates
6. audit_logs
7. api_keys
8. subscriptions
```

### Data Migration
When migrating existing data:
1. Create default tenant for existing users
2. Migrate service configurations to new JSONB format
3. Create audit logs for historical actions
4. Update foreign key references

## Performance Considerations

### Indexes
- All foreign keys are indexed
- Frequently queried fields have indexes
- Composite indexes for complex queries
- Partial indexes for filtered queries

### Query Optimization
- Use GORM's preloading for related data
- Implement pagination for large result sets
- Use database-level filtering instead of application-level
- Consider read replicas for heavy read workloads

### Maintenance
- Regular VACUUM and ANALYZE operations
- Monitor index usage and remove unused indexes
- Archive old audit logs periodically
- Implement connection pooling

## Security Considerations

### Data Protection
- Passwords are hashed with bcrypt
- Sensitive configuration data should be encrypted
- API keys are generated with cryptographically secure random
- Audit logs capture all data modifications

### Access Control
- Row-level security for tenant isolation
- Role-based access control
- API key scoping to specific tenants
- Regular security audits

## Backup and Recovery

### Backup Strategy
- Daily full backups
- Point-in-time recovery capabilities
- Backup verification procedures
- Offsite backup storage

### Recovery Procedures
- Automated recovery testing
- Documented recovery procedures
- RTO/RPO targets defined
- Disaster recovery plan

## Monitoring

### Database Metrics
- Connection pool usage
- Query performance
- Index usage statistics
- Table size and growth
- Replication lag (if applicable)

### Alerting
- Long-running queries
- High connection usage
- Disk space warnings
- Replication failures
- Backup failures
