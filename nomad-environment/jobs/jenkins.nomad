job "jenkins-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "jenkins" {
    count = 1

    network {
      port "http" {
        static = 8088
      }
      port "agent" {
        static = 50000
      }
    }

    volume "jenkins-data" {
      type      = "host"
      read_only = false
      source    = "jenkins-data"
    }

    task "jenkins" {
      driver = "docker"

      config {
        image = "jenkins/jenkins:lts"
        ports = ["http", "agent"]
        
        volumes = [
          "jenkins-data:/var/jenkins_home"
        ]
        
        # Run as root to avoid permission issues in development
        privileged = true
      }

      env {
        JENKINS_OPTS = "--httpPort=8088"
        JAVA_OPTS = "-Djenkins.install.runSetupWizard=false -Djava.awt.headless=true"
      }

      template {
        data = <<EOF
jenkins.model.Jenkins.instance.setSlaveAgentPort(50000)
jenkins.model.Jenkins.instance.save()

import jenkins.model.*
import hudson.security.*
import hudson.security.csrf.DefaultCrumbIssuer
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)

// Set authorization strategy
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Enable CSRF protection
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))

// Disable remoting security
instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

instance.save()
EOF
        destination = "local/init.groovy"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }

      service {
        name = "jenkins"
        port = "http"

        check {
          type     = "http"
          path     = "/login"
          interval = "30s"
          timeout  = "10s"
        }
      }

      service {
        name = "jenkins-agent"
        port = "agent"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}
