# @summary Install Supabase dependencies and requirements
#
# This class installs Docker, Docker Compose, Git, and other system dependencies
# required for running Supabase. It also clones the Supabase repository.
#
class supabase::install {
  # Ensure we're on a supported Ubuntu version
  if $facts['os']['family'] != 'Debian' {
    fail("This module only supports Ubuntu/Debian. Detected: ${facts['os']['name']} (${facts['os']['family']})")
  }

  # System user for running Supabase
  user { 'supabase':
    ensure     => present,
    home       => '/home/supabase',
    managehome => true,
    shell      => '/bin/bash',
    system     => true,
    groups     => ['docker'],
    require    => Package['docker-ce'],
  }

  # Required packages
  $packages = [
    'curl',
    'gnupg',
    'lsb-release',
    'ca-certificates',
    'git',
    'ufw',
    'cron',
  ]

  package { $packages:
    ensure => present,
  }

  # Add Docker's official GPG key and repository
  apt::source { 'docker':
    location => 'https://download.docker.com/linux/ubuntu',
    release  => $facts['os']['distro']['codename'],
    repos    => 'stable',
    key      => {
      'id'     => '9DC858229FC7DD38854AE2D88D81803C0EBFCD88',
      'source' => 'https://download.docker.com/linux/ubuntu/gpg',
    },
    include  => {
      'src' => false,
      'deb' => true,
    },
    require  => Package['ca-certificates'],
  }

  # Install Docker
  package { ['docker-ce', 'docker-ce-cli', 'containerd.io', 'docker-buildx-plugin']:
    ensure  => present,
    require => Apt::Source['docker'],
  }

  # Start and enable Docker service
  service { 'docker':
    ensure    => running,
    enable    => true,
    require   => Package['docker-ce'],
  }

  # Install Docker Compose
  file { '/usr/local/bin/docker-compose':
    ensure => present,
    mode   => '0755',
    source => "https://github.com/docker/compose/releases/download/v${supabase::docker_compose_version}/docker-compose-linux-x86_64",
    require => Package['curl'],
  }

  # Create symlink for docker compose plugin compatibility
  file { '/usr/bin/docker-compose':
    ensure  => link,
    target  => '/usr/local/bin/docker-compose',
    require => File['/usr/local/bin/docker-compose'],
  }

  # Create installation directory
  file { $supabase::install_directory:
    ensure => directory,
    owner  => 'supabase',
    group  => 'supabase',
    mode   => '0755',
    require => User['supabase'],
  }

  # Clone Supabase repository
  vcsrepo { "${supabase::install_directory}/supabase":
    ensure   => present,
    provider => git,
    source   => 'https://github.com/supabase/supabase.git',
    revision => $supabase::supabase_version,
    user     => 'supabase',
    group    => 'supabase',
    depth    => 1,
    require  => [
      File[$supabase::install_directory],
      Package['git'],
      User['supabase'],
    ],
  }

  # Create required directories for Supabase
  $supabase_dirs = [
    "${supabase::install_directory}/volumes",
    "${supabase::install_directory}/volumes/db",
    "${supabase::install_directory}/volumes/storage",
    "${supabase::install_directory}/volumes/functions",
    "${supabase::install_directory}/backups",
    "${supabase::install_directory}/logs",
  ]

  file { $supabase_dirs:
    ensure  => directory,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    require => File[$supabase::install_directory],
  }

  # Configure firewall rules
  include firewall

  # Allow SSH (ensure we don't lock ourselves out)
  firewall { '100 allow ssh':
    dport  => 22,
    proto  => tcp,
    action => accept,
  }

  # Allow HTTP and HTTPS
  firewall { '200 allow http':
    dport  => 80,
    proto  => tcp,
    action => accept,
  }

  firewall { '201 allow https':
    dport  => 443,
    proto  => tcp,
    action => accept,
  }

  # Allow Supabase API port (8000) - will be proxied later
  firewall { '300 allow supabase api':
    dport  => 8000,
    proto  => tcp,
    action => accept,
  }

  # Optionally allow direct PostgreSQL access (commented out by default for security)
  # Uncomment if you need direct database access from external sources
  # firewall { '400 allow postgresql':
  #   dport  => 5432,
  #   proto  => tcp,
  #   action => accept,
  # }

  # Set default firewall policy to drop
  firewalls_purge { 'accept':
    purge => true,
  }

  # Ensure system is up to date
  exec { 'apt-update':
    command => '/usr/bin/apt update',
    before  => Package[$packages],
  }
} 