job "kafka-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "kafka" {
    count = 1

    network {
      port "kafka" {
        static = 9092
      }
      port "jmx" {
        static = 7203
      }
    }

    volume "kafka-data" {
      type      = "host"
      read_only = false
      source    = "kafka-data"
    }

    task "kafka" {
      driver = "docker"

      config {
        image = "confluentinc/cp-kafka:latest"
        ports = ["kafka", "jmx"]
        
        env = {
          KAFKA_BROKER_ID                  = "1"
          KAFKA_ZOOKEEPER_CONNECT          = "localhost:2181"
          KAFKA_LISTENER_SECURITY_PROTOCOL_MAP = "PLAINTEXT:PLAINTEXT,PLAINTEXT_INTERNAL:PLAINTEXT"
          KAFKA_LISTENERS                  = "PLAINTEXT://0.0.0.0:9092,PLAINTEXT_INTERNAL://localhost:29092"
          KAFKA_ADVERTISED_LISTENERS      = "PLAINTEXT://localhost:9092,PLAINTEXT_INTERNAL://localhost:29092"
          KAFKA_LOG_DIRS                   = "/var/lib/kafka"
        }

        volumes = [
          "kafka-data:/var/lib/kafka"
        ]
      }

      resources {
        cpu    = 1000
        memory = 2048
      }

      service {
        name = "kafka"
        port = "kafka"

        check {
          type     = "tcp"
          interval = "30s"
          timeout  = "10s"
        }
      }
    }
  }
}
