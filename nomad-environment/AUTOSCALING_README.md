# Nomad Autoscaler Setup Guide

This guide provides comprehensive instructions for setting up and using the Nomad Autoscaler in your development environment.

## 🚀 Quick Start

1. **Deploy required services** first:
   ```bash
   # Start the Nomad environment
   ./init-scripts/start-nomad-environment.sh
   
   # Deploy Prometheus (required for metrics)
   # Select option 1 from the menu
   ```

2. **Deploy the Nomad Autoscaler**:
   ```bash
   # Select option 27 from the menu
   # OR use the management script
   ./scripts/manage-autoscaler.sh deploy
   ```

3. **Check the autoscaler status**:
   ```bash
   ./scripts/manage-autoscaler.sh status
   ```

## 📋 Prerequisites

- Nomad server running
- Consul server running  
- Prometheus deployed (for metrics collection)
- Docker running
- Services you want to scale must be deployed

## 🔧 Configuration

### Autoscaler Configuration

The autoscaler is configured to:
- Connect to Nomad at `http://localhost:4646`
- Use Prometheus at `http://localhost:9090` for metrics
- Listen on port `8080` for API requests
- Load scaling policies from the policies directory

### Scaling Policies

The autoscaler comes with pre-configured policies for:

#### 1. Node.js CPU Scaling
- **Target**: `nodejs-server` job
- **Metric**: Average CPU usage
- **Threshold**: 70%
- **Min/Max**: 1-5 instances
- **Cooldown**: 2 minutes

#### 2. Redis Memory Scaling
- **Target**: `redis-server` job
- **Metric**: Average memory usage
- **Threshold**: 80%
- **Min/Max**: 1-3 instances
- **Cooldown**: 3 minutes

#### 3. PHP Request-based Scaling
- **Target**: `php-server` job
- **Metric**: HTTP requests per second
- **Threshold**: 100 req/sec
- **Min/Max**: 1-10 instances
- **Cooldown**: 1 minute

#### 4. Java CPU Scaling
- **Target**: `java-server` job
- **Metric**: Average CPU usage
- **Threshold**: 75%
- **Min/Max**: 1-8 instances
- **Cooldown**: 2 minutes

#### 5. PostgreSQL Connection Scaling
- **Target**: `postgresql-server` job
- **Metric**: Active connections
- **Threshold**: 20-80 connections
- **Min/Max**: 1-3 instances
- **Cooldown**: 5 minutes

## 🛠️ Management Commands

### Using the Management Script

```bash
# Deploy autoscaler
./scripts/manage-autoscaler.sh deploy

# Check status
./scripts/manage-autoscaler.sh status

# View logs
./scripts/manage-autoscaler.sh logs

# List active policies
./scripts/manage-autoscaler.sh policies

# Show scaling history
./scripts/manage-autoscaler.sh history

# Stop autoscaler
./scripts/manage-autoscaler.sh stop

# Show recommendations
./scripts/manage-autoscaler.sh recommendations

# Create custom policy template
./scripts/manage-autoscaler.sh create-policy my-policy
```

### Direct API Access

The autoscaler exposes a REST API on port 8080:

```bash
# Health check
curl http://localhost:8080/v1/health

# List policies
curl http://localhost:8080/v1/policies

# View scaling history
curl http://localhost:8080/v1/scaling/history

# Get policy details
curl http://localhost:8080/v1/policy/<policy-id>
```

## 📊 Monitoring

### Autoscaler Metrics

The autoscaler exposes Prometheus metrics at:
- `http://localhost:8080/v1/metrics`

### Key Metrics to Monitor

- `nomad_autoscaler_policy_evaluation_count`
- `nomad_autoscaler_scaling_actions_total`
- `nomad_autoscaler_target_value`
- `nomad_autoscaler_current_value`

### Integration with Prometheus

The autoscaler is pre-configured to scrape metrics from:
- Nomad API (`http://localhost:4646`)
- Prometheus (`http://localhost:9090`)

## 🔄 Job Configuration for Autoscaling

### Adding Scaling to Existing Jobs

To enable autoscaling for a job, add a `scaling` stanza to your job specification:

```hcl
job "my-app" {
  datacenters = ["dc1"]
  type        = "service"

  group "app" {
    count = 1
    
    scaling {
      enabled = true
      min     = 1
      max     = 5
      
      policy {
        cooldown            = "2m"
        evaluation_interval = "10s"
        
        check "cpu_usage" {
          source = "prometheus"
          query  = "avg(nomad_client_allocs_cpu_total_percent{job=\"my-app\"})"
          
          strategy "target-value" {
            target = 70
          }
        }
      }
    }
    
    # ... rest of job definition
  }
}
```

### Scaling Strategies

#### 1. Target-Value Strategy
Maintains a target value for a metric:
```hcl
strategy "target-value" {
  target = 70
}
```

#### 2. Threshold Strategy
Scales based on upper and lower bounds:
```hcl
strategy "threshold" {
  upper_bound = 80
  lower_bound = 20
}
```

#### 3. Fixed-Value Strategy
Scales to a fixed number of instances:
```hcl
strategy "fixed-value" {
  value = 3
}
```

## 🎯 Custom Scaling Policies

### Creating Custom Policies

1. **Generate a template**:
   ```bash
   ./scripts/manage-autoscaler.sh create-policy my-custom-policy
   ```

2. **Edit the policy file**:
   ```hcl
   scaling "my_custom_policy" {
     enabled = true
     min     = 1
     max     = 10

     policy {
       cooldown            = "5m"
       evaluation_interval = "30s"

       check "custom_metric" {
         source = "prometheus"
         query  = "your_custom_prometheus_query"

         strategy "target-value" {
           target = 50
         }
       }
     }

     target {
       Namespace = "default"
       Job       = "your-job-name"
       Group     = "your-group-name"
     }
   }
   ```

3. **Apply the policy** by redeploying the autoscaler or using the API.

### Common Prometheus Queries

- **CPU Usage**: `avg(nomad_client_allocs_cpu_total_percent{job="job-name"})`
- **Memory Usage**: `avg(nomad_client_allocs_memory_usage{job="job-name"})`
- **Request Rate**: `rate(nginx_http_requests_total{job="job-name"}[5m])`
- **Queue Length**: `rabbitmq_queue_messages{job="job-name"}`
- **Active Connections**: `pg_stat_activity_count{job="job-name"}`

## 🔍 Troubleshooting

### Common Issues

1. **Autoscaler not starting**:
   - Check Nomad is running: `nomad node status`
   - Check Prometheus is available: `curl http://localhost:9090`
   - Check Docker is running: `docker ps`

2. **Policies not evaluating**:
   - Verify job has scaling stanza
   - Check Prometheus has metrics for the job
   - Ensure metric queries return values

3. **Scaling not triggering**:
   - Check cooldown periods
   - Verify thresholds are appropriate
   - Review autoscaler logs

### Debug Commands

```bash
# Check autoscaler logs
./scripts/manage-autoscaler.sh logs

# Check job status
nomad job status <job-name>

# Check allocation details
nomad alloc status <allocation-id>

# Test Prometheus query
curl "http://localhost:9090/api/v1/query?query=<your-query>"
```

## 📈 Best Practices

### 1. Metric Selection
- Use stable, representative metrics
- Avoid noisy or volatile metrics
- Consider lag time in metric collection

### 2. Threshold Tuning
- Start with conservative thresholds
- Monitor scaling behavior over time
- Adjust based on application characteristics

### 3. Cooldown Periods
- Set appropriate cooldown periods
- Prevent thrashing between scale up/down
- Consider metric collection frequency

### 4. Resource Limits
- Set realistic min/max values
- Consider infrastructure capacity
- Monitor resource usage patterns

### 5. Testing
- Test scaling policies in dev environment
- Gradually increase load to verify behavior
- Monitor metrics during testing

## 🌟 Advanced Features

### Time-based Scaling
```hcl
check "business_hours" {
  source = "prometheus"
  query  = "hour()"
  
  strategy "threshold" {
    upper_bound = 18  # 6 PM
    lower_bound = 8   # 8 AM
  }
}
```

### Multi-metric Scaling
```hcl
check "cpu_and_memory" {
  source = "prometheus"
  query  = "avg(nomad_client_allocs_cpu_total_percent{job=\"my-app\"}) + avg(nomad_client_allocs_memory_usage{job=\"my-app\"})"
  
  strategy "target-value" {
    target = 100
  }
}
```

### External Metrics
```hcl
check "queue_length" {
  source = "prometheus"
  query  = "rabbitmq_queue_messages{queue=\"work-queue\"}"
  
  strategy "target-value" {
    target = 10
  }
}
```

## 🔗 Resources

- [Nomad Autoscaler Documentation](https://www.nomadproject.io/docs/autoscaling)
- [Prometheus Query Language](https://prometheus.io/docs/prometheus/latest/querying/)
- [Nomad Job Specification](https://www.nomadproject.io/docs/job-specification)

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review autoscaler logs: `./scripts/manage-autoscaler.sh logs`
3. Verify your Prometheus queries independently
4. Check job and allocation status in Nomad UI

## 🔄 Updates

To update the autoscaler:
1. Stop the current autoscaler: `./scripts/manage-autoscaler.sh stop`
2. Update the job file with new configuration
3. Redeploy: `./scripts/manage-autoscaler.sh deploy`

---

**Note**: This autoscaler setup is configured for development environments. For production use, consider additional security, monitoring, and resource management practices.
