# Host volume definitions for Nomad services
# These volumes need to be registered with Nomad before deploying services

# GitLab CE volumes
volume "gitlab_config" {
  type    = "host"
  plugin  = "host"
  source  = "gitlab_config"
  
  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

volume "gitlab_logs" {
  type    = "host"
  plugin  = "host"
  source  = "gitlab_logs"
  
  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

volume "gitlab_data" {
  type    = "host"
  plugin  = "host"
  source  = "gitlab_data"
  
  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

# Redis volume
volume "redis_data" {
  type    = "host"
  plugin  = "host"
  source  = "redis_data"
  
  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

# PostgreSQL volume (if needed)
volume "postgresql_data" {
  type    = "host"
  plugin  = "host"
  source  = "postgresql_data"
  
  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}
