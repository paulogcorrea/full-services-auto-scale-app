job "nodejs-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "nodejs" {
    count = 1
    
    scaling {
      enabled = true
      min     = 1
      max     = 5
      
      policy {
        cooldown            = "2m"
        evaluation_interval = "10s"
        
        check "avg_cpu" {
          source = "prometheus"
          query  = "avg(nomad_client_allocs_cpu_total_percent{job=\"nodejs-server\"})"
          
          strategy "target-value" {
            target = 70
          }
        }
      }
    }

    network {
      port "http" {
        static = 3000
      }
    }

    task "node-app" {
      driver = "docker"

      config {
        image = "node:18-alpine"
        ports = ["http"]
        
        command = "sh"
        args = ["/usr/src/app/start.sh"]

        mount {
          type   = "bind"
          source = "local/package.json"
          target = "/usr/src/app/package.json"
        }
        
        mount {
          type   = "bind"
          source = "local/index.js"
          target = "/usr/src/app/index.js"
        }
        
        mount {
          type   = "bind"
          source = "local/start.sh"
          target = "/usr/src/app/start.sh"
        }
      }

      template {
        data = <<EOF
{
  "name": "nodejs-backend",
  "version": "1.0.0",
  "description": "Node.js Backend API Server",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0"
  }
}
EOF
        destination = "local/package.json"
      }

      template {
        data = <<EOF
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const app = express();
const port = 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// In-memory data store for demo
let users = [
  { id: 1, name: 'John Doe', email: 'john@example.com' },
  { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
];

let todos = [
  { id: 1, title: 'Learn Node.js', completed: false, userId: 1 },
  { id: 2, title: 'Build API', completed: true, userId: 1 },
  { id: 3, title: 'Deploy to production', completed: false, userId: 2 }
];

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Node.js Backend API Server',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      users: '/api/users',
      todos: '/api/todos'
    }
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

// Users API
app.get('/api/users', (req, res) => {
  res.json(users);
});

app.get('/api/users/:id', (req, res) => {
  const user = users.find(u => u.id === parseInt(req.params.id));
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  res.json(user);
});

app.post('/api/users', (req, res) => {
  const { name, email } = req.body;
  if (!name || !email) {
    return res.status(400).json({ error: 'Name and email are required' });
  }
  
  const newUser = {
    id: users.length + 1,
    name,
    email
  };
  
  users.push(newUser);
  res.status(201).json(newUser);
});

// Todos API
app.get('/api/todos', (req, res) => {
  const { userId } = req.query;
  let filteredTodos = todos;
  
  if (userId) {
    filteredTodos = todos.filter(t => t.userId === parseInt(userId));
  }
  
  res.json(filteredTodos);
});

app.get('/api/todos/:id', (req, res) => {
  const todo = todos.find(t => t.id === parseInt(req.params.id));
  if (!todo) {
    return res.status(404).json({ error: 'Todo not found' });
  }
  res.json(todo);
});

app.post('/api/todos', (req, res) => {
  const { title, userId } = req.body;
  if (!title || !userId) {
    return res.status(400).json({ error: 'Title and userId are required' });
  }
  
  const newTodo = {
    id: todos.length + 1,
    title,
    completed: false,
    userId: parseInt(userId)
  };
  
  todos.push(newTodo);
  res.status(201).json(newTodo);
});

app.put('/api/todos/:id', (req, res) => {
  const todoIndex = todos.findIndex(t => t.id === parseInt(req.params.id));
  if (todoIndex === -1) {
    return res.status(404).json({ error: 'Todo not found' });
  }
  
  const { title, completed } = req.body;
  if (title !== undefined) todos[todoIndex].title = title;
  if (completed !== undefined) todos[todoIndex].completed = completed;
  
  res.json(todos[todoIndex]);
});

app.delete('/api/todos/:id', (req, res) => {
  const todoIndex = todos.findIndex(t => t.id === parseInt(req.params.id));
  if (todoIndex === -1) {
    return res.status(404).json({ error: 'Todo not found' });
  }
  
  const deletedTodo = todos.splice(todoIndex, 1)[0];
  res.json(deletedTodo);
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Node.js Backend API Server running on port ${port}`);
  console.log(`Available endpoints:`);
  console.log(`  GET  /health`);
  console.log(`  GET  /api/users`);
  console.log(`  POST /api/users`);
  console.log(`  GET  /api/todos`);
  console.log(`  POST /api/todos`);
  console.log(`  PUT  /api/todos/:id`);
  console.log(`  DELETE /api/todos/:id`);
});
EOF
        destination = "local/index.js"
      }

      template {
        data = <<EOF
#!/bin/sh
cd /usr/src/app
npm install
node index.js
EOF
        destination = "local/start.sh"
        perms = "755"
      }

      resources {
        cpu    = 256
        memory = 512
      }

      service {
        name = "nodejs-server"
        port = "http"

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
