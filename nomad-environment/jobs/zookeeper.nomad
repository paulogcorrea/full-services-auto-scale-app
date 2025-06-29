job "zookeeper-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "zookeeper" {
    count = 1

    network {
      port "client" {
        static = 2181
      }
      port "follower" {
        static = 2888
      }
      port "election" {
        static = 3888
      }
    }

    volume "zookeeper-data" {
      type      = "host"
      read_only = false
      source    = "zookeeper-data"
    }

    volume "zookeeper-logs" {
      type      = "host"
      read_only = false
      source    = "zookeeper-logs"
    }

    task "zookeeper" {
      driver = "docker"

      config {
        image = "confluentinc/cp-zookeeper:latest"
        ports = ["client", "follower", "election"]
        
        volumes = [
          "zookeeper-data:/var/lib/zookeeper/data",
          "zookeeper-logs:/var/lib/zookeeper/log"
        ]
      }

      env {
        ZOOKEEPER_CLIENT_PORT     = "2181"
        ZOOKEEPER_TICK_TIME       = "2000"
        ZOOKEEPER_INIT_LIMIT      = "5"
        ZOOKEEPER_SYNC_LIMIT      = "2"
        ZOOKEEPER_SERVER_ID       = "1"
        ZOOKEEPER_SERVERS         = "localhost:2888:3888"
        ZOOKEEPER_LOG4J_ROOT_LOGLEVEL = "INFO"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "zookeeper"
        port = "client"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
