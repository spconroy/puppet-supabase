# Example Puppet manifest for installing Supabase
# Copy this file and customize for your environment

# Basic installation example
node 'supabase-basic.example.com' {
  class { 'supabase':
    postgres_password    => 'MySecureDbPassword123!',
    jwt_secret          => 'your-super-secret-jwt-token-with-at-least-32-characters-here',
    anon_key            => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFub24iLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY0NjA2NzI2MiwiZXhwIjoxOTYxNjQzMjYyfQ.example',
    service_role_key    => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNlcnZpY2Vfcm9sZSIsInJvbGUiOiJzZXJ2aWNlX3JvbGUiLCJpYXQiOjE2NDYwNjcyNjIsImV4cCI6MTk2MTY0MzI2Mn0.example',
    domain_name         => 'supabase.example.com',
    dashboard_username  => 'admin',
    dashboard_password  => 'SecureDashboardPassword123!',
  }
}

# Production installation with all features
node 'supabase-prod.example.com' {
  class { 'supabase':
    # Required parameters
    postgres_password     => 'ProductionSecurePassword123!',
    jwt_secret           => 'production-jwt-secret-40-plus-characters-secure',
    anon_key             => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.production.anon.key',
    service_role_key     => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.production.service.key',
    domain_name          => 'api.mycompany.com',
    
    # Dashboard access
    dashboard_username   => 'admin',
    dashboard_password   => 'ProductionDashboardPassword123!',
    
    # SSL and security
    enable_ssl           => true,
    
    # Backup configuration
    enable_backups       => true,
    backup_retention_days => 30,
    
    # Email configuration
    smtp_host            => 'smtp.mailgun.org',
    smtp_port            => 587,
    smtp_user            => 'postmaster@mg.mycompany.com',
    smtp_pass            => 'mailgun-api-key',
    smtp_admin_email     => 'admin@mycompany.com',
    
    # S3 storage
    storage_backend      => 's3',
    s3_bucket           => 'mycompany-supabase-storage',
    s3_region           => 'us-west-2',
    aws_access_key_id   => 'AKIAIOSFODNN7EXAMPLE',
    aws_secret_access_key => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    
    # Application URLs
    site_url                 => 'https://myapp.com',
    additional_redirect_urls => [
      'https://myapp.com',
      'https://staging.myapp.com',
      'http://localhost:3000',
    ],
    
    # Monitoring
    enable_monitoring    => true,
  }
}

# Development/testing installation
node 'supabase-dev.example.com' {
  class { 'supabase':
    postgres_password    => 'dev-password-123',
    jwt_secret          => 'dev-jwt-secret-for-testing-minimum-40-chars',
    anon_key            => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dev.anon.key',
    service_role_key    => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dev.service.key',
    domain_name         => 'localhost',
    
    # Minimal configuration for development
    enable_ssl          => false,
    enable_backups      => false,
    enable_monitoring   => false,
    
    # Development-friendly settings
    dashboard_username  => 'dev',
    dashboard_password  => 'dev123',
  }
}

# Installation with custom storage location
node 'supabase-custom.example.com' {
  class { 'supabase':
    postgres_password    => 'CustomSecurePassword123!',
    jwt_secret          => 'custom-jwt-secret-40-plus-characters-here',
    anon_key            => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.custom.anon.key',
    service_role_key    => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.custom.service.key',
    domain_name         => 'supabase.custom.com',
    
    # Custom installation directory
    install_directory   => '/opt/custom-supabase',
    
    # File storage with custom settings
    storage_backend     => 'file',
    enable_backups      => true,
    backup_retention_days => 14,
  }
}

# Example using Hiera for sensitive data (recommended)
node 'supabase-hiera.example.com' {
  class { 'supabase':
    postgres_password    => lookup('supabase::postgres_password'),
    jwt_secret          => lookup('supabase::jwt_secret'),
    anon_key            => lookup('supabase::anon_key'),
    service_role_key    => lookup('supabase::service_role_key'),
    domain_name         => lookup('supabase::domain_name'),
    dashboard_username  => lookup('supabase::dashboard_username'),
    dashboard_password  => lookup('supabase::dashboard_password'),
    
    # SMTP settings from Hiera
    smtp_host           => lookup('supabase::smtp_host', { 'default_value' => undef }),
    smtp_port           => lookup('supabase::smtp_port', { 'default_value' => undef }),
    smtp_user           => lookup('supabase::smtp_user', { 'default_value' => undef }),
    smtp_pass           => lookup('supabase::smtp_pass', { 'default_value' => undef }),
    smtp_admin_email    => lookup('supabase::smtp_admin_email', { 'default_value' => undef }),
  }
}

# Notes:
# 1. Replace all example passwords and keys with secure, randomly generated values
# 2. Generate proper JWT keys using https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys
# 3. Ensure your domain DNS is pointing to the server before enabling SSL
# 4. For production, consider using Hiera to manage sensitive data
# 5. Always use strong passwords and secure your API keys 