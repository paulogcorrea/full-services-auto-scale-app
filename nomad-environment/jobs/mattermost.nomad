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

    restart {
      attempts = 3
      interval = "5m"
      delay    = "25s"
      mode     = "fail"
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
        # Database configuration (using dedicated MySQL instance)
        MM_SQLSETTINGS_DRIVERNAME = "mysql"
        MM_SQLSETTINGS_DATASOURCE = "mmuser:mmuser_password@tcp(192.168.15.5:3307)/mattermost?charset=utf8mb4,utf8&readTimeout=30s&writeTimeout=30s"
        
        # Server configuration
        MM_SERVICESETTINGS_SITEURL = "http://192.168.15.5:8065"
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
