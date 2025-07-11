# @summary Configure Supabase environment and Docker Compose
#
# This class configures the Supabase environment variables and sets up
# the Docker Compose configuration for production deployment.
#
class supabase::config {
  $docker_dir = "${supabase::install_directory}/supabase/docker"
  
  # Generate additional environment variables
  $pooler_tenant_id = 'supabase-tenant'
  $logflare_api_key = fqdn_rand_string(32, undef, 'logflare-api-key')
  $logflare_logger_backend_api_key = fqdn_rand_string(32, undef, 'logflare-logger-backend-api-key')

  # Create the main .env file from template
  file { "${docker_dir}/.env":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0600',
    content => epp('supabase/supabase.env.epp', {
      postgres_password                => $supabase::postgres_password,
      jwt_secret                      => $supabase::jwt_secret,
      anon_key                        => $supabase::anon_key,
      service_role_key                => $supabase::service_role_key,
      dashboard_username              => $supabase::dashboard_username,
      dashboard_password              => $supabase::dashboard_password,
      site_url                        => $supabase::site_url,
      additional_redirect_urls        => join($supabase::additional_redirect_urls, ','),
      api_external_url                => "https://api.${supabase::domain_name}",
      supabase_public_url             => "https://studio.${supabase::domain_name}",
      pooler_tenant_id                => $pooler_tenant_id,
      logflare_api_key                => $logflare_api_key,
      logflare_logger_backend_api_key => $logflare_logger_backend_api_key,
      smtp_host                       => $supabase::smtp_host,
      smtp_port                       => $supabase::smtp_port,
      smtp_user                       => $supabase::smtp_user,
      smtp_pass                       => $supabase::smtp_pass,
      smtp_admin_email                => $supabase::smtp_admin_email,
      storage_backend                 => $supabase::storage_backend,
      s3_bucket                       => $supabase::s3_bucket,
      s3_region                       => $supabase::s3_region,
      s3_endpoint                     => $supabase::s3_endpoint,
      aws_access_key_id               => $supabase::aws_access_key_id,
      aws_secret_access_key           => $supabase::aws_secret_access_key,
    }),
    require => Vcsrepo["${supabase::install_directory}/supabase"],
  }

  # Create production Docker Compose override file
  file { "${docker_dir}/docker-compose.prod.yml":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0644',
    content => epp('supabase/docker-compose.prod.yml.epp', {
      domain_name    => $supabase::domain_name,
      enable_ssl     => $supabase::enable_ssl,
      install_directory => $supabase::install_directory,
    }),
    require => Vcsrepo["${supabase::install_directory}/supabase"],
  }

  # Create nginx configuration for reverse proxy
  if $supabase::enable_ssl {
    file { "${supabase::install_directory}/nginx":
      ensure => directory,
      owner  => 'supabase',
      group  => 'supabase',
      mode   => '0755',
    }

    file { "${supabase::install_directory}/nginx/nginx.conf":
      ensure  => present,
      owner   => 'supabase',
      group   => 'supabase',
      mode    => '0644',
      content => epp('supabase/nginx.conf.epp', {
        domain_name => $supabase::domain_name,
      }),
      require => File["${supabase::install_directory}/nginx"],
    }

    # Create certbot directory for SSL certificates
    file { "${supabase::install_directory}/certbot":
      ensure => directory,
      owner  => 'supabase',
      group  => 'supabase',
      mode   => '0755',
    }

    file { ["${supabase::install_directory}/certbot/conf", "${supabase::install_directory}/certbot/www"]:
      ensure  => directory,
      owner   => 'supabase',
      group   => 'supabase',
      mode    => '0755',
      require => File["${supabase::install_directory}/certbot"],
    }
  }

  # Create systemd service file for Supabase
  file { '/etc/systemd/system/supabase.service':
    ensure  => present,
    mode    => '0644',
    content => epp('supabase/supabase.service.epp', {
      docker_dir => $docker_dir,
      user       => 'supabase',
      group      => 'supabase',
    }),
    notify  => Exec['systemd-reload'],
  }

  # Reload systemd when service file changes
  exec { 'systemd-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  # Set proper ownership for all Supabase files
  exec { 'fix-supabase-ownership':
    command => "/bin/chown -R supabase:supabase ${supabase::install_directory}",
    unless  => "/usr/bin/test \"\$(stat -c '%U:%G' ${supabase::install_directory})\" = 'supabase:supabase'",
    require => [
      File["${docker_dir}/.env"],
      File["${docker_dir}/docker-compose.prod.yml"],
    ],
  }

  # Create log rotation configuration
  file { '/etc/logrotate.d/supabase':
    ensure  => present,
    mode    => '0644',
    content => epp('supabase/logrotate.epp', {
      log_directory => "${supabase::install_directory}/logs",
    }),
  }

  # Create health check script
  file { "${supabase::install_directory}/health-check.sh":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    content => epp('supabase/health-check.sh.epp', {
      docker_dir => $docker_dir,
    }),
    require => File[$supabase::install_directory],
  }

  # Create update script
  file { "${supabase::install_directory}/update-supabase.sh":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    content => epp('supabase/update-supabase.sh.epp', {
      docker_dir        => $docker_dir,
      install_directory => $supabase::install_directory,
    }),
    require => File[$supabase::install_directory],
  }
} 