job "rabbitmq-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "rabbitmq" {
    count = 1

    network {
      port "amqp" {
        static = 5672
      }
      port "management" {
        static = 15672
      }
    }

    volume "rabbitmq-data" {
      type      = "host"
      read_only = false
      source    = "rabbitmq-data"
    }

    task "rabbitmq" {
      driver = "docker"

      config {
        image = "rabbitmq:3-management-alpine"
        ports = ["amqp", "management"]
        
        volumes = [
          "rabbitmq-data:/var/lib/rabbitmq"
        ]
      }

      env {
        RABBITMQ_DEFAULT_USER     = "${RABBITMQ_DEFAULT_USER}"
        RABBITMQ_DEFAULT_PASS     = "${RABBITMQ_DEFAULT_PASS}"
        RABBITMQ_DEFAULT_VHOST    = "/"
        RABBITMQ_ERLANG_COOKIE    = "SWQOKODSQALRPCLNMEQG"
      }

      resources {
        cpu    = 512
        memory = 512
      }

      service {
        name = "rabbitmq-amqp"
        port = "amqp"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "3s"
        }
      }

      service {
        name = "rabbitmq-management"
        port = "management"

        check {
          type     = "http"
          path     = "/"
          interval = "15s"
          timeout  = "5s"
        }
      }
    }
  }
}
