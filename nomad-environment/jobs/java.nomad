job "java-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "java" {
    count = 1

    network {
      port "http" {
        static = 8090
      }
    }

    task "spring-boot-app" {
      driver = "docker"

      config {
        image = "openjdk:17-jdk-slim"
        ports = ["http"]
        
        command = "/bin/bash"
        args = ["-c", "cd /app && javac -cp '.:*' HelloWorld.java && java -cp '.:*' HelloWorld"]
        
        mount {
          type   = "bind"
          source = "local/HelloWorld.java"
          target = "/app/HelloWorld.java"
        }
        
        mount {
          type   = "bind"
          source = "local/start.sh"
          target = "/app/start.sh"
        }
      }

      template {
        data = <<EOF
import java.io.*;
import java.net.*;

public class HelloWorld {
    public static void main(String[] args) throws IOException {
        int port = 8090;
        ServerSocket serverSocket = new ServerSocket(port);
        System.out.println("Java HTTP Server started on port " + port);
        
        while (true) {
            Socket clientSocket = serverSocket.accept();
            PrintWriter out = new PrintWriter(clientSocket.getOutputStream(), true);
            
            String response = "HTTP/1.1 200 OK\r\n" +
                            "Content-Type: text/html\r\n" +
                            "Connection: close\r\n\r\n" +
                            "<html><body>" +
                            "<h1>Java Application Server</h1>" +
                            "<p>Java Version: " + System.getProperty("java.version") + "</p>" +
                            "<p>Server Time: " + new java.util.Date() + "</p>" +
                            "</body></html>";
            
            out.println(response);
            out.close();
            clientSocket.close();
        }
    }
}
EOF
        destination = "local/HelloWorld.java"
      }

      template {
        data = <<EOF
#!/bin/bash
cd /app
javac HelloWorld.java
java HelloWorld
EOF
        destination = "local/start.sh"
        perms       = "755"
      }

      resources {
        cpu    = 512
        memory = 512
      }

      service {
        name = "java-server"
        port = "http"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
