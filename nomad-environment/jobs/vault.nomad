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
        image = "hashicorp/vault:latest"
        ports = ["vault"]
        
        command = "vault"
        args = ["server", "-dev", "-dev-listen-address=0.0.0.0:8200"]
      }

      env {
        VAULT_DEV_ROOT_TOKEN_ID = "myroot"
        VAULT_DEV_LISTEN_ADDRESS = "0.0.0.0:8200"
        VAULT_API_ADDR = "http://0.0.0.0:8200"
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
          path     = "/v1/sys/health?standbyok=true"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
