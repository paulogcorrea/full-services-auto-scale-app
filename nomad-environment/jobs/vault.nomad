job "vault-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "vault" {
    count = 1

    network {
      port "vault" {
        static = 8200
      }
    }

    task "vault" {
      driver = "docker"

      config {
        image = "vault:latest"
        ports = ["vault"]
        
        cap_add = ["IPC_LOCK"]
        
        mount {
          type   = "bind"
          source = "local/vault.hcl"
          target = "/vault/config/vault.hcl"
        }
      }

      template {
        data = <<EOF
ui = true

storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}

api_addr = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"
EOF
        destination = "local/vault.hcl"
      }

      env {
        VAULT_DEV_ROOT_TOKEN_ID = "myroot"
        VAULT_DEV_LISTEN_ADDRESS = "0.0.0.0:8200"
      }

      resources {
        cpu    = 256
        memory = 512
      }

      service {
        name = "vault"
        port = "vault"

        check {
          type     = "http"
          path     = "/v1/sys/health"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
