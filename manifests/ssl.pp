# @summary Configure SSL certificates for Supabase
#
# This class sets up Let's Encrypt SSL certificates and nginx reverse proxy
# for secure HTTPS access to Supabase services.
#
class supabase::ssl {
  # Install certbot for Let's Encrypt
  package { 'certbot':
    ensure => present,
  }

  package { 'python3-certbot-nginx':
    ensure  => present,
    require => Package['certbot'],
  }

  # Install nginx
  package { 'nginx':
    ensure => present,
  }

  # Stop the default nginx service (we'll manage it via our configuration)
  service { 'nginx':
    ensure  => stopped,
    enable  => false,
    require => Package['nginx'],
  }

  # Create nginx configuration for Supabase
  file { '/etc/nginx/sites-available/supabase':
    ensure  => present,
    mode    => '0644',
    content => epp('supabase/nginx-supabase.conf.epp', {
      domain_name => $supabase::domain_name,
    }),
    require => Package['nginx'],
    notify  => Service['nginx-supabase'],
  }

  # Remove default nginx site
  file { '/etc/nginx/sites-enabled/default':
    ensure => absent,
  }

  # Enable Supabase nginx site
  file { '/etc/nginx/sites-enabled/supabase':
    ensure  => link,
    target  => '/etc/nginx/sites-available/supabase',
    require => File['/etc/nginx/sites-available/supabase'],
    notify  => Service['nginx-supabase'],
  }

  # Create systemd service for nginx with Supabase
  file { '/etc/systemd/system/nginx-supabase.service':
    ensure  => present,
    mode    => '0644',
    content => epp('supabase/nginx-supabase.service.epp'),
    notify  => Exec['systemd-reload-ssl'],
  }

  # Reload systemd when service file changes
  exec { 'systemd-reload-ssl':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  # Start nginx service
  service { 'nginx-supabase':
    ensure    => running,
    enable    => true,
    provider  => 'systemd',
    require   => [
      File['/etc/systemd/system/nginx-supabase.service'],
      Exec['systemd-reload-ssl'],
    ],
    subscribe => File['/etc/nginx/sites-available/supabase'],
  }

  # Create SSL certificate generation script
  file { "${supabase::install_directory}/setup-ssl.sh":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => epp('supabase/setup-ssl.sh.epp', {
      domain_name => $supabase::domain_name,
    }),
    require => [
      Package['certbot'],
      Package['python3-certbot-nginx'],
    ],
  }

  # Create SSL certificate renewal script
  file { "${supabase::install_directory}/renew-ssl.sh":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => epp('supabase/renew-ssl.sh.epp'),
    require => Package['certbot'],
  }

  # Set up automatic SSL certificate renewal
  cron { 'ssl-certificate-renewal':
    command => "${supabase::install_directory}/renew-ssl.sh",
    user    => 'root',
    hour    => 3,
    minute  => 30,
    weekday => 1, # Run on Mondays
    require => File["${supabase::install_directory}/renew-ssl.sh"],
  }

  # Create script to check SSL certificate status
  file { "${supabase::install_directory}/check-ssl.sh":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => epp('supabase/check-ssl.sh.epp', {
      domain_name => $supabase::domain_name,
    }),
    require => Package['certbot'],
  }
} 