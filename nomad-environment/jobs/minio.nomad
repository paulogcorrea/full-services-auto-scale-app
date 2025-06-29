job "minio-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "minio" {
    count = 1

    network {
      port "api" {
        static = 9000
      }
      port "console" {
        static = 9001
      }
    }

    volume "minio-data" {
      type      = "host"
      read_only = false
      source    = "minio-data"
    }

    task "minio" {
      driver = "docker"

      config {
        image = "minio/minio:latest"
        ports = ["api", "console"]
        
        args = [
          "server",
          "/data",
          "--console-address",
          ":9001"
        ]
        
        volumes = [
          "minio-data:/data"
        ]
      }

      env {
        MINIO_ROOT_USER     = "minioadmin"
        MINIO_ROOT_PASSWORD = "minioadmin123"
        MINIO_BROWSER_REDIRECT_URL = "http://localhost:9001"
      }

      template {
        data = <<EOF
#!/bin/bash

# Wait for MinIO to be ready
sleep 10

# Configure MinIO client
mc alias set local http://localhost:9000 minioadmin minioadmin123

# Create default buckets
mc mb local/uploads --ignore-existing
mc mb local/backups --ignore-existing
mc mb local/images --ignore-existing
mc mb local/documents --ignore-existing
mc mb local/logs --ignore-existing

# Set bucket policies (public read for uploads, private for others)
mc anonymous set download local/uploads
mc anonymous set none local/backups
mc anonymous set none local/images
mc anonymous set none local/documents
mc anonymous set none local/logs

# Create sample files
echo "Welcome to MinIO Object Storage!" > /tmp/welcome.txt
mc cp /tmp/welcome.txt local/uploads/welcome.txt

echo "MinIO configuration completed successfully!"
EOF
        destination = "local/init-minio.sh"
        perms       = "755"
      }

      resources {
        cpu    = 512
        memory = 1024
      }

      service {
        name = "minio-api"
        port = "api"

        check {
          type     = "http"
          path     = "/minio/health/live"
          interval = "30s"
          timeout  = "10s"
        }
      }

      service {
        name = "minio-console"
        port = "console"

        check {
          type     = "http"
          path     = "/"
          interval = "30s"
          timeout  = "10s"
        }
      }
    }

    task "minio-setup" {
      driver = "docker"

      config {
        image = "minio/mc:latest"
        
        mount {
          type   = "bind"
          source = "local/init-minio.sh"
          target = "/init-minio.sh"
        }
      }

      lifecycle {
        hook    = "poststart"
        sidecar = false
      }

      env {
        MC_HOST_local = "http://minioadmin:minioadmin123@${NOMAD_IP_api}:${NOMAD_PORT_api}"
      }

      template {
        data = <<EOF
#!/bin/bash
set -e

echo "Waiting for MinIO to be ready..."
sleep 15

# Configure MinIO client
mc alias set local http://host.docker.internal:9000 minioadmin minioadmin123

# Wait for MinIO to be fully ready
until mc admin info local > /dev/null 2>&1; do
  echo "Waiting for MinIO server..."
  sleep 5
done

echo "MinIO is ready. Creating buckets..."

# Create default buckets
mc mb local/uploads --ignore-existing || true
mc mb local/backups --ignore-existing || true
mc mb local/images --ignore-existing || true
mc mb local/documents --ignore-existing || true
mc mb local/logs --ignore-existing || true

# Set bucket policies
mc anonymous set download local/uploads || true
mc anonymous set none local/backups || true
mc anonymous set none local/images || true
mc anonymous set none local/documents || true
mc anonymous set none local/logs || true

# Create sample files
echo "Welcome to MinIO Object Storage! This is a sample file." > /tmp/welcome.txt
echo "MinIO Configuration Date: $(date)" > /tmp/config-info.txt
mc cp /tmp/welcome.txt local/uploads/welcome.txt || true
mc cp /tmp/config-info.txt local/uploads/config-info.txt || true

echo "MinIO buckets and sample data created successfully!"
echo "Available buckets:"
mc ls local
EOF
        destination = "local/setup-buckets.sh"
        perms       = "755"
      }

      args = ["/bin/sh", "/setup-buckets.sh"]

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
