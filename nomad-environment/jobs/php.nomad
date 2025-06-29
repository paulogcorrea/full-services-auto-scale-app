job "php-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "php" {
    count = 1

    network {
      port "http" {
        static = 8080
      }
    }

    task "php-fpm" {
      driver = "docker"

      config {
        image = "php:8.2-fpm-alpine"
        ports = ["http"]
        
        mount {
          type   = "bind"
          source = "local/index.php"
          target = "/var/www/html/index.php"
        }
      }

      template {
        data = <<EOF
<?php
phpinfo();
?>
EOF
        destination = "local/index.php"
      }

      resources {
        cpu    = 256
        memory = 256
      }

      service {
        name = "php-server"
        port = "http"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:alpine"
        ports = ["http"]
        
        mount {
          type   = "bind"
          source = "local/nginx.conf"
          target = "/etc/nginx/nginx.conf"
        }
      }

      template {
        data = <<EOF
events {
    worker_connections 1024;
}

http {
    upstream php {
        server 127.0.0.1:9000;
    }

    server {
        listen 8080;
        root /var/www/html;
        index index.php;

        location ~ \.php$ {
            fastcgi_pass php;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }
}
EOF
        destination = "local/nginx.conf"
      }

      resources {
        cpu    = 128
        memory = 128
      }
    }
  }
}
