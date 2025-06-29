# Nomad Environment Manager

A comprehensive solution to start a HashiCorp Nomad server and deploy various services in a containerized environment.

## Prerequisites

Before running this application, make sure you have the following installed:

1. **HashiCorp Nomad**
   ```bash
   brew tap hashicorp/tap
   brew install hashicorp/tap/nomad
   ```

2. **Docker**
   - Install Docker Desktop for macOS
   - Ensure Docker is running before starting the application

3. **Git** (if cloning from repository)

## Available Services

This environment manager supports the following services:

- **PHP Server** (Port 8080) - PHP 8.2 with Nginx
- **MySQL Database** (Port 3306) - MySQL 8.0 with test database
- **PostgreSQL Database** (Port 5432) - PostgreSQL 15 with test database
- **HashiCorp Vault** (Port 8200) - Secret management server
- **Sonatype Nexus** (Port 8081) - Repository manager
- **JFrog Artifactory** (Port 8082) - Universal artifact repository
- **Java Application Server** (Port 8090) - Simple Java HTTP server
- **RabbitMQ Message Broker** (Port 5672/15672) - Message queue with management UI

## Quick Start

1. **Make the script executable:**
   ```bash
   chmod +x start-nomad-environment.sh
   ```

2. **Run the environment manager:**
   ```bash
   ./start-nomad-environment.sh
   ```

3. **Select services from the interactive menu**

4. **Access the Nomad UI:**
   - Open http://localhost:4646 in your browser

## Usage

### Starting the Environment

Run the main script:
```bash
./start-nomad-environment.sh
```

The script will:
1. Check if Nomad and Docker are installed and running
2. Start a Nomad server in development mode
3. Present an interactive menu to select services

### Service Selection Menu

```
================== Available Services ==================

1) Artifactory Server (artifactory)
2) Java Application Server (java)
3) MySQL Database Server (mysql)
4) Sonatype Nexus Repository (nexus)
5) PHP Server (php)
6) PostgreSQL Database Server (postgresql)
7) HashiCorp Vault (vault)
8) Deploy Custom Application
0) Exit
```

### Deploying Custom Applications

Select option 8 to deploy your own Docker-based application. You'll be prompted for:
- Application name
- Docker image
- Port to expose

### Service Access

Once deployed, services will be available at:

- **PHP Server**: http://localhost:8080
- **MySQL**: localhost:3306 (user: testuser, password: testpass)
- **PostgreSQL**: localhost:5432 (user: postgres, password: postgres)
- **Vault**: http://localhost:8200 (root token: myroot)
- **Nexus**: http://localhost:8081 (admin/admin123)
- **Artifactory**: http://localhost:8082 (admin/password)
- **Java Server**: http://localhost:8090
- **RabbitMQ**: localhost:5672 (AMQP), http://localhost:15672 (Management UI - admin/admin123)

## Directory Structure

```
nomad-environment/
├── start-nomad-environment.sh   # Main script
├── jobs/                        # Nomad job files
│   ├── php.nomad
│   ├── mysql.nomad
│   ├── postgresql.nomad
│   ├── vault.nomad
│   ├── nexus.nomad
│   ├── artifactory.nomad
│   └── java.nomad
├── configs/                     # Configuration files
├── scripts/                     # Additional utility scripts
└── README.md                    # This file
```

## Stopping the Environment

The script includes cleanup functionality:
- Press Ctrl+C or select option 0 to exit
- All running jobs will be stopped
- The Nomad server will be terminated

## Troubleshooting

### Nomad Not Starting
- Ensure no other Nomad instances are running
- Check if port 4646 is available
- Review `nomad.log` for error messages

### Docker Issues
- Ensure Docker Desktop is running
- Check if you have sufficient disk space
- Try restarting Docker if containers fail to start

### Port Conflicts
- Check if any of the default ports are in use
- Modify the job files to use different ports if needed

### Memory Issues
- Some services (Nexus, Artifactory) require significant memory
- Ensure Docker has enough memory allocated
- Consider reducing the number of concurrent services

## Customization

### Adding New Services

1. Create a new `.nomad` file in the `jobs/` directory
2. Add the service to the `SERVICES` array in the main script
3. Follow the existing patterns for service configuration

### Modifying Resource Allocation

Edit the individual job files to adjust:
- CPU allocation
- Memory limits
- Port assignments

### Persistent Data

Some services use Docker volumes for data persistence:
- MySQL: `mysql-data` volume
- PostgreSQL: `postgres-data` volume
- Nexus: `nexus-data` volume
- Artifactory: `artifactory-data` volume

Data will persist between restarts of the same service.

## Security Notes

This environment is designed for development and testing purposes:
- Default passwords are used for simplicity
- TLS is disabled for ease of setup
- Services are exposed on all interfaces

**Do not use this configuration in production environments.**

## License

This project is provided as-is for educational and development purposes.
