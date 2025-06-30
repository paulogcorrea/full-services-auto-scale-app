job "mysql-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "mysql" {
    count = 1

    network {
      port "mysql" {
        static = 3306
      }
    }

    volume "mysql-data" {
      type      = "host"
      read_only = false
      source    = "mysql-data"
    }

    task "mysql" {
      driver = "docker"

      config {
        image = "mysql:8.0"
        ports = ["mysql"]
        
        volumes = [
          "mysql-data:/var/lib/mysql"
        ]
      }

      env {
        MYSQL_ROOT_PASSWORD = "${MYSQL_ROOT_PASSWORD}"
        MYSQL_DATABASE      = "testdb"
        MYSQL_USER         = "testuser"
        MYSQL_PASSWORD     = "testpass"
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      service {
        name = "mysql"
        port = "mysql"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
