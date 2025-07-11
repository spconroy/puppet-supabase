# Progressive Supabase Setup Examples
# Start basic and add features as needed

# =============================================================================
# PHASE 1: Basic Installation (Day 1)
# =============================================================================
node 'supabase.example.com' {
  class { 'supabase':
    # Minimum required parameters
    postgres_password    => 'secure-db-password-123',
    jwt_secret          => 'your-40-character-jwt-secret-here',
    anon_key            => 'your-generated-anon-key',
    service_role_key    => 'your-generated-service-role-key',
    domain_name         => 'supabase.example.com',
    
    # Use defaults for everything else
    # - File storage
    # - 7-day backup retention  
    # - No SSL (development)
    # - Basic monitoring only
  }
}

# =============================================================================
# PHASE 2: Add SSL and Better Security (Week 1)
# =============================================================================
node 'supabase.example.com' {
  class { 'supabase':
    # Same required parameters
    postgres_password    => 'secure-db-password-123',
    jwt_secret          => 'your-40-character-jwt-secret-here',
    anon_key            => 'your-generated-anon-key',
    service_role_key    => 'your-generated-service-role-key',
    domain_name         => 'supabase.example.com',
    
    # ADD: SSL/TLS encryption
    enable_ssl          => true,
    
    # ADD: Better dashboard security
    dashboard_username  => 'admin',
    dashboard_password  => 'much-more-secure-password-123',
  }
}
# After applying: run `sudo /opt/supabase/setup-ssl.sh`

# =============================================================================
# PHASE 3: Add Email Support (Month 1)
# =============================================================================
node 'supabase.example.com' {
  class { 'supabase':
    # Same core configuration
    postgres_password    => 'secure-db-password-123',
    jwt_secret          => 'your-40-character-jwt-secret-here',
    anon_key            => 'your-generated-anon-key',
    service_role_key    => 'your-generated-service-role-key',
    domain_name         => 'supabase.example.com',
    enable_ssl          => true,
    dashboard_username  => 'admin',
    dashboard_password  => 'much-more-secure-password-123',
    
    # ADD: Email/SMTP configuration
    smtp_host           => 'smtp.mailgun.org',
    smtp_port           => 587,
    smtp_user           => 'postmaster@mg.example.com',
    smtp_pass           => 'mailgun-api-key',
    smtp_admin_email    => 'admin@example.com',
  }
}

# =============================================================================
# PHASE 4: Production Ready with S3 and Monitoring (Month 2-3)
# =============================================================================
node 'supabase.example.com' {
  class { 'supabase':
    # Core configuration (stable)
    postgres_password    => 'secure-db-password-123',
    jwt_secret          => 'your-40-character-jwt-secret-here',
    anon_key            => 'your-generated-anon-key',
    service_role_key    => 'your-generated-service-role-key',
    domain_name         => 'supabase.example.com',
    enable_ssl          => true,
    dashboard_username  => 'admin',
    dashboard_password  => 'much-more-secure-password-123',
    
    # Email (stable)
    smtp_host           => 'smtp.mailgun.org',
    smtp_port           => 587,
    smtp_user           => 'postmaster@mg.example.com',
    smtp_pass           => 'mailgun-api-key',
    smtp_admin_email    => 'admin@example.com',
    
    # ADD: S3 storage for scalability
    storage_backend     => 's3',
    s3_bucket          => 'company-supabase-storage',
    s3_region          => 'us-west-2',
    aws_access_key_id  => 'AKIAIOSFODNN7EXAMPLE',
    aws_secret_access_key => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    
    # ADD: Extended backup retention
    backup_retention_days => 30,
    
    # ADD: Advanced monitoring
    enable_monitoring   => true,
    
    # ADD: Production app URLs
    site_url            => 'https://myapp.com',
    additional_redirect_urls => [
      'https://myapp.com',
      'https://staging.myapp.com',
      'https://admin.myapp.com',
    ],
  }
}

# =============================================================================
# How to Apply Changes
# =============================================================================

# 1. Update your site.pp with new configuration
# 2. Run: puppet apply site.pp
# 3. Services will automatically restart with new config
# 4. For SSL: run setup script after first enabling SSL
# 5. For monitoring: access Grafana at http://yourdomain:3001

# =============================================================================
# Rollback Strategy
# =============================================================================

# If something breaks, you can always roll back:
# 1. Restore previous site.pp configuration
# 2. Run: puppet apply site.pp  
# 3. Or manually: sudo systemctl restart supabase

# =============================================================================
# Zero-Downtime Updates
# =============================================================================

# Most configuration changes can be applied with minimal downtime:
# - Environment variables: ~30 seconds restart
# - SSL certificates: No downtime (background renewal)
# - Storage backend: Requires planning and data migration
# - Database changes: Use backup/restore for major changes 