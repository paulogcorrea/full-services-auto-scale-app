job "mysql-mattermost" {
  datacenters = ["dc1"]
  type        = "service"

  group "mysql" {
    count = 1

    network {
      port "mysql" {
        static = 3307  # Different port from main MySQL (3306)
      }
    }

    volume "mysql-mattermost-data" {
      type      = "host"
      read_only = false
      source    = "mysql-mattermost-data"
    }

    task "mysql" {
      driver = "docker"

      config {
        image = "mysql:8.0"
        ports = ["mysql"]
        
        volumes = [
          "mysql-mattermost-data:/var/lib/mysql"
        ]
        
        # Add command to configure MySQL for Mattermost
        command = "mysqld"
        args = [
          "--character-set-server=utf8mb4",
          "--collation-server=utf8mb4_unicode_ci",
          "--innodb-file-format=Barracuda",
          "--innodb-large-prefix=1",
          "--innodb-file-per-table=1"
        ]
      }

      env {
        MYSQL_ROOT_PASSWORD = "mattermost_root_pass"
        MYSQL_DATABASE      = "mattermost"
        MYSQL_USER         = "mmuser"
        MYSQL_PASSWORD     = "mmuser_password"
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      service {
        name = "mysql-mattermost"
        port = "mysql"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "3s"
        }
        
        check {
          type     = "script"
          name     = "mysql-ready"
          command  = "/bin/sh"
          args     = ["-c", "mysqladmin ping -h localhost -u root -p$MYSQL_ROOT_PASSWORD"]
          interval = "30s"
          timeout  = "5s"
        }
      }
    }
  }
}
