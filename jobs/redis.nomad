job "redis" {
  datacenters = ["dc1"]
  type        = "service"
  
  group "redis" {
    count = 1
    
    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }
    
    network {
      port "redis" {
        static = 6379
      }
    }
    
    volume "redis_data" {
      type      = "host"
      read_only = false
      source    = "redis_data"
    }
    
    task "redis" {
      driver = "docker"
      
      config {
        image = "redis:7-alpine"
        
        ports = ["redis"]
        
        args = [
          "redis-server",
          "--appendonly", "yes",
          "--appendfsync", "everysec",
          "--maxmemory", "512mb",
          "--maxmemory-policy", "allkeys-lru"
        ]
        
        mount {
          type   = "volume"
          target = "/data"
          source = "redis_data"
        }
      }
      
      resources {
        cpu    = 500   # 0.5 CPU cores
        memory = 512   # 512MB RAM
      }
      
      service {
        name = "redis"
        port = "redis"
        
        tags = [
          "redis",
          "cache",
          "database",
          "key-value"
        ]
        
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
        
        check {
          type     = "script"
          name     = "redis-ping"
          command  = "/usr/local/bin/redis-cli"
          args     = ["ping"]
          interval = "30s"
          timeout  = "5s"
        }
      }
    }
  }
}
