job "sonarqube-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "sonarqube" {
    count = 1

    network {
      port "http" {
        static = 9002
      }
    }

    volume "sonarqube-data" {
      type      = "host"
      read_only = false
      source    = "sonarqube-data"
    }

    volume "sonarqube-logs" {
      type      = "host"
      read_only = false
      source    = "sonarqube-logs"
    }

    volume "sonarqube-extensions" {
      type      = "host"
      read_only = false
      source    = "sonarqube-extensions"
    }

    task "sonarqube" {
      driver = "docker"

      config {
        image = "sonarqube:community"
        ports = ["http"]
        
        volumes = [
          "sonarqube-data:/opt/sonarqube/data",
          "sonarqube-logs:/opt/sonarqube/logs",
          "sonarqube-extensions:/opt/sonarqube/extensions"
        ]
        
        mount {
          type   = "bind"
          source = "local/sonar.properties"
          target = "/opt/sonarqube/conf/sonar.properties"
        }
      }

      env {
        SONAR_JDBC_URL      = "jdbc:h2:file:/opt/sonarqube/data/h2/sonar"
        SONAR_JDBC_USERNAME = "sonar"
        SONAR_JDBC_PASSWORD = "sonar"
        SONAR_WEB_HOST      = "0.0.0.0"
        SONAR_WEB_PORT      = "9002"
        SONAR_CE_JAVAADDITIONALOPTS = "-Xmx512m -Xms128m"
        SONAR_WEB_JAVAADDITIONALOPTS = "-Xmx512m -Xms128m"
      }

      template {
        data = <<EOF
# SonarQube Configuration for Development Environment

# Web Server Configuration
sonar.web.host=0.0.0.0
sonar.web.port=9002
sonar.web.context=
sonar.web.javaOpts=-Xmx512m -Xms128m -XX:+HeapDumpOnOutOfMemoryError

# Database Configuration (H2 for development)
sonar.jdbc.url=jdbc:h2:file:/opt/sonarqube/data/h2/sonar
sonar.jdbc.username=sonar
sonar.jdbc.password=sonar

# Compute Engine Configuration
sonar.ce.javaOpts=-Xmx512m -Xms128m -XX:+HeapDumpOnOutOfMemoryError

# Elasticsearch Configuration
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m -XX:+HeapDumpOnOutOfMemoryError

# Paths
sonar.path.data=/opt/sonarqube/data
sonar.path.temp=/opt/sonarqube/temp
sonar.path.logs=/opt/sonarqube/logs

# Security Configuration (Development)
sonar.forceAuthentication=false
sonar.security.realm=

# Update Center Configuration
sonar.updatecenter.activate=true

# Logging Configuration
sonar.log.level=INFO
sonar.log.rollingPolicy=time:yyyy-MM-dd
sonar.log.maxFiles=7

# Plugin Configuration
sonar.plugins.risk.consent=ACCEPTED

# Development Settings
sonar.developerMode=true
EOF
        destination = "local/sonar.properties"
      }

      resources {
        cpu    = 1000
        memory = 2048
      }

      service {
        name = "sonarqube"
        port = "http"

        check {
          type     = "http"
          path     = "/api/system/status"
          interval = "60s"
          timeout  = "30s"
        }
      }
    }
  }
}
