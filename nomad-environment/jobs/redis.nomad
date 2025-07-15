job "redis-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "redis" {
    count = 1
    
    scaling {
      enabled = true
      min     = 1
      max     = 3
      
      policy {
        cooldown            = "3m"
        evaluation_interval = "15s"
        
        check "avg_memory" {
          source = "prometheus"
          query  = "avg(nomad_client_allocs_memory_usage{job=\"redis-server\"})"
          
          strategy "target-value" {
            target = 80
          }
        }
      }
    }

    network {
      port "redis" {
        static = 6379
      }
    }

    volume "redis-data" {
      type      = "host"
      read_only = false
      source    = "redis-data"
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:7-alpine"
        ports = ["redis"]
        
        args = [
          "redis-server",
          "/usr/local/etc/redis/redis.conf"
        ]
        
        volumes = [
          "redis-data:/data"
        ]
        
        mount {
          type   = "bind"
          source = "local/redis.conf"
          target = "/usr/local/etc/redis/redis.conf"
        }
      }

      template {
        data = <<EOF
# Redis configuration for development environment

# Network
bind 0.0.0.0
port 6379
protected-mode no

# General
daemonize no
pidfile /var/run/redis_6379.pid

# Logging
loglevel notice
logfile ""

# Persistence
save 900 1
save 300 10
save 60 10000

stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /data

# Replication
replica-serve-stale-data yes
replica-read-only yes

# Security (development settings)
# requirepass redis123

# Memory management
maxmemory 256mb
maxmemory-policy allkeys-lru

# AOF persistence
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Slow log
slowlog-log-slower-than 10000
slowlog-max-len 128

# Advanced config
tcp-keepalive 300
timeout 0

# Client output buffer limits
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

# Redis modules (if needed)
# loadmodule /usr/lib/redis/modules/redisearch.so
# loadmodule /usr/lib/redis/modules/redisjson.so
EOF
        destination = "local/redis.conf"
      }

      resources {
        cpu    = 256
        memory = 512
      }

      service {
        name = "redis"
        port = "redis"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
