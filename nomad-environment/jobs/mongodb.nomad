job "mongodb-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "mongodb" {
    count = 1

    network {
      port "mongodb" {
        static = 27017
      }
    }

    volume "mongodb-data" {
      type      = "host"
      read_only = false
      source    = "mongodb-data"
    }

    task "mongodb" {
      driver = "docker"

      config {
        image = "mongo:latest"
        ports = ["mongodb"]

        volumes = [
          "mongodb-data:/data/db"
        ]
        
        mount {
          type   = "bind"
          source = "local/init-mongo.js"
          target = "/docker-entrypoint-initdb.d/init-mongo.js"
        }
      }
      
      env {
        MONGO_INITDB_ROOT_USERNAME = "${MONGODB_ROOT_USERNAME}"
        MONGO_INITDB_ROOT_PASSWORD = "${MONGODB_ROOT_PASSWORD}"
        MONGO_INITDB_DATABASE      = "testdb"
      }
      
      template {
        data = <<EOF
// Initialize MongoDB with sample data
db = db.getSiblingDB('testdb');

// Create a user for the test database
db.createUser({
  user: 'testuser',
  pwd: 'testpass',
  roles: [
    {
      role: 'readWrite',
      db: 'testdb'
    }
  ]
});

// Create sample collections and data
db.users.insertMany([
  { name: 'John Doe', email: 'john@example.com', age: 30 },
  { name: 'Jane Smith', email: 'jane@example.com', age: 25 },
  { name: 'Bob Johnson', email: 'bob@example.com', age: 35 }
]);

db.products.insertMany([
  { name: 'Laptop', price: 999.99, category: 'Electronics' },
  { name: 'Mouse', price: 25.50, category: 'Electronics' },
  { name: 'Desk', price: 199.99, category: 'Furniture' }
]);

print('MongoDB initialized with sample data');
EOF
        destination = "local/init-mongo.js"
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      service {
        name = "mongodb"
        port = "mongodb"

        check {
          type     = "tcp"
          interval = "30s"
          timeout  = "10s"
        }
      }
    }
  }
}
