job "postgresql-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "postgres" {
    count = 1

    network {
      port "postgres" {
        static = 5432
      }
    }

    volume "postgres-data" {
      type      = "host"
      read_only = false
      source    = "postgres-data"
    }

    task "postgresql" {
      driver = "docker"

      config {
        image = "postgres:15-alpine"
        ports = ["postgres"]
        
        volumes = [
          "postgres-data:/var/lib/postgresql/data"
        ]
      }

      env {
        POSTGRES_DB       = "testdb"
        POSTGRES_USER     = "${POSTGRES_USER}"
        POSTGRES_PASSWORD = "${POSTGRES_PASSWORD}"
        PGDATA           = "/var/lib/postgresql/data/pgdata"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "postgresql"
        port = "postgres"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
