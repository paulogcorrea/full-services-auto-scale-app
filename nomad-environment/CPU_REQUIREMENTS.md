# CPU Requirements for Nomad Environment Services

## Individual Service CPU Allocations

### 📊 OBSERVABILITY & MONITORING (6 services)
- **Prometheus**: 500 MHz (0.5 cores)
- **Grafana**: 500 MHz (0.5 cores)
- **Loki**: 500 MHz (0.5 cores)
- **Promtail**: 200 MHz (0.2 cores)
- **Node Exporter**: 100 MHz (0.1 cores)
- **cAdvisor**: 300 MHz (0.3 cores)
- **Subtotal**: 2,100 MHz (2.1 cores)

### 💾 DATABASES (4 services)
- **MySQL**: 500 MHz (0.5 cores)
- **PostgreSQL**: 500 MHz (0.5 cores)
- **MongoDB**: 500 MHz (0.5 cores)
- **Redis**: 256 MHz (0.256 cores)
- **Subtotal**: 1,756 MHz (1.756 cores)

### 🔄 MESSAGING & STREAMING (3 services)
- **ZooKeeper**: 500 MHz (0.5 cores)
- **Kafka**: 1,000 MHz (1.0 cores)
- **RabbitMQ**: 512 MHz (0.512 cores)
- **Subtotal**: 2,012 MHz (2.012 cores)

### 🌐 WEB SERVERS & APIs (3 services)
- **PHP**: 256 MHz + 128 MHz = 384 MHz (0.384 cores)
- **Node.js**: 256 MHz (0.256 cores)
- **Java**: 512 MHz (0.512 cores)
- **Subtotal**: 1,152 MHz (1.152 cores)

### 🔧 DEVELOPMENT TOOLS (4 services)
- **Jenkins**: 1,000 MHz (1.0 cores)
- **SonarQube**: 1,000 MHz (1.0 cores)
- **Nexus**: 1,000 MHz (1.0 cores)
- **Artifactory**: 1,000 MHz (1.0 cores)
- **Subtotal**: 4,000 MHz (4.0 cores)

### 🔐 SECURITY & STORAGE (4 services)
- **Vault**: 256 MHz (0.256 cores)
- **Keycloak**: 1,000 MHz (1.0 cores)
- **MinIO**: 100 MHz + 512 MHz = 612 MHz (0.612 cores)
- **Mattermost**: 1,000 MHz (1.0 cores)
- **Subtotal**: 2,868 MHz (2.868 cores)

### 🌍 NETWORKING & PROXY (2 services)
- **Traefik**: 500 MHz (0.5 cores)
- **Traefik HTTPS**: 500 MHz (0.5 cores)
- **Subtotal**: 1,000 MHz (1.0 cores)

### 🐳 GENERIC DEPLOYMENT (1 service)
- **Generic Docker**: 1,000 MHz (1.0 cores)
- **Subtotal**: 1,000 MHz (1.0 cores)

### 🏗️ INFRASTRUCTURE (2 services)
- **Consul**: 256 MHz (0.256 cores)
- **Nomad**: ~500 MHz (0.5 cores) *estimated*
- **Subtotal**: 756 MHz (0.756 cores)

## Summary

### Total CPU if ALL services are deployed:
- **Total allocated CPU**: ~16.6 cores (16,644 MHz)
- **Recommended minimum**: 20+ cores for comfortable operation
- **Recommended optimal**: 24-32+ cores for production-like performance

### Typical deployment scenarios:

#### Light Development (5-8 services):
- Vault, MySQL, Redis, Traefik, Grafana, Prometheus
- **Total**: ~3-4 cores needed

#### Medium Development (10-15 services):
- Add Jenkins, Node.js, MongoDB, RabbitMQ, Loki
- **Total**: ~6-8 cores needed

#### Full Stack Development (20+ services):
- Most services except heavy ones like SonarQube, Artifactory
- **Total**: ~12-16 cores needed

#### Complete Environment (All 27+ services):
- All services running simultaneously
- **Total**: ~20+ cores needed

## Memory Considerations
While CPU is important, don't forget about RAM:
- **Minimum**: 16GB RAM
- **Recommended**: 32GB+ RAM for full deployment
- **Optimal**: 64GB+ RAM for heavy workloads

## Performance Tips
1. **Start with essential services** and add more as needed
2. **Monitor resource usage** with cAdvisor and Prometheus
3. **Use Docker resource limits** to prevent any single service from consuming too much
4. **Consider vertical scaling** by increasing allocations for heavily used services
5. **Use SSD storage** for better I/O performance

## MacOS Specific Notes
- Docker Desktop on macOS has overhead compared to native Linux
- Allocate sufficient resources to Docker Desktop (Settings > Resources)
- Consider using Colima or OrbStack as Docker Desktop alternatives for better performance
