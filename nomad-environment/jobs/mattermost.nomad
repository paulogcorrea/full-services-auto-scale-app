job "mattermost-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "mattermost" {
    count = 1

    network {
      port "http" {
        static = 8065
      }
    }

    volume "mattermost-data" {
      type      = "host"
      read_only = false
      source    = "mattermost-data"
    }

    volume "mattermost-logs" {
      type      = "host"
      read_only = false
      source    = "mattermost-logs"
    }

    volume "mattermost-config" {
      type      = "host"
      read_only = false
      source    = "mattermost-config"
    }

    task "mattermost" {
      driver = "docker"

      config {
        image = "mattermost/mattermost-team-edition:latest"
        ports = ["http"]
        
        volumes = [
          "mattermost-data:/mattermost/data",
          "mattermost-logs:/mattermost/logs",
          "mattermost-config:/mattermost/config"
        ]
      }

      env {
        # Database configuration (using built-in SQLite for simplicity)
        MM_SQLSETTINGS_DRIVERNAME = "sqlite3"
        MM_SQLSETTINGS_DATASOURCE = "/mattermost/data/mattermost.db"
        
        # Server configuration
        MM_SERVICESETTINGS_SITEURL = "http://localhost:8065"
        MM_SERVICESETTINGS_LISTENADDRESS = ":8065"
        MM_SERVICESETTINGS_ENABLELOCALMODE = "true"
        MM_SERVICESETTINGS_ENABLEDEVELOPER = "true"
        
        # Email configuration (disabled for development)
        MM_EMAILSETTINGS_ENABLESIGNUPWITHEMAIL = "true"
        MM_EMAILSETTINGS_ENABLESIGNINWITHEMAIL = "true"
        MM_EMAILSETTINGS_ENABLESIGNINWITHUSERNAME = "true"
        MM_EMAILSETTINGS_REQUIREEMAILVERIFICATION = "false"
        MM_EMAILSETTINGS_SENDEMAILNOTIFICATIONS = "false"
        
        # Team settings
        MM_TEAMSETTINGS_ENABLETEAMCREATION = "true"
        MM_TEAMSETTINGS_ENABLEUSERCREATION = "true"
        MM_TEAMSETTINGS_ENABLEOPENSERVER = "true"
        MM_TEAMSETTINGS_RESTRICTCREATIONTODOMAINS = ""
        
        # File settings
        MM_FILESETTINGS_ENABLEFILEATTACHMENTS = "true"
        MM_FILESETTINGS_MAXFILESIZE = "52428800"
        
        # Plugin settings
        MM_PLUGINSETTINGS_ENABLE = "true"
        MM_PLUGINSETTINGS_ENABLEUPLOADS = "true"
        
        # Security settings (relaxed for development)
        MM_SERVICESETTINGS_ENABLEINSECUREOUTGOINGCONNECTIONS = "true"
        
        # Logging
        MM_LOGSETTINGS_ENABLECONSOLE = "true"
        MM_LOGSETTINGS_CONSOLELEVEL = "INFO"
        MM_LOGSETTINGS_ENABLEFILE = "true"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }

      service {
        name = "mattermost"
        port = "http"

        check {
          type     = "http"
          path     = "/api/v4/system/ping"
          interval = "30s"
          timeout  = "10s"
        }
      }
    }
  }
}
