# @summary Manage Supabase services
#
# This class manages the Supabase Docker Compose services and ensures
# they are running properly.
#
class supabase::service {
  $docker_dir = "${supabase::install_directory}/supabase/docker"

  # Pull Docker images before starting services
  exec { 'pull-supabase-images':
    command     => '/usr/local/bin/docker-compose pull',
    cwd         => $docker_dir,
    user        => 'supabase',
    group       => 'supabase',
    environment => ["HOME=/home/supabase"],
    require     => [
      File["${docker_dir}/.env"],
      File['/usr/local/bin/docker-compose'],
    ],
    before      => Service['supabase'],
  }

  # Start Supabase services
  service { 'supabase':
    ensure    => running,
    enable    => true,
    provider  => 'systemd',
    require   => [
      File['/etc/systemd/system/supabase.service'],
      Exec['systemd-reload'],
      Exec['pull-supabase-images'],
    ],
    subscribe => [
      File["${docker_dir}/.env"],
      File["${docker_dir}/docker-compose.prod.yml"],
    ],
  }

  # Create a script to wait for services to be healthy
  file { "${supabase::install_directory}/wait-for-services.sh":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    content => epp('supabase/wait-for-services.sh.epp', {
      docker_dir => $docker_dir,
    }),
    require => File[$supabase::install_directory],
  }

  # Wait for services to be healthy after starting
  exec { 'wait-for-supabase-healthy':
    command     => "${supabase::install_directory}/wait-for-services.sh",
    user        => 'supabase',
    group       => 'supabase',
    environment => ["HOME=/home/supabase"],
    timeout     => 300,
    require     => [
      Service['supabase'],
      File["${supabase::install_directory}/wait-for-services.sh"],
    ],
    refreshonly => true,
    subscribe   => Service['supabase'],
  }

  # Set up monitoring cron job for service health
  cron { 'supabase-health-check':
    command => "${supabase::install_directory}/health-check.sh",
    user    => 'supabase',
    minute  => '*/5',
    require => File["${supabase::install_directory}/health-check.sh"],
  }

  # Log rotation cron job
  cron { 'supabase-log-rotation':
    command => '/usr/sbin/logrotate /etc/logrotate.d/supabase',
    user    => 'root',
    hour    => 2,
    minute  => 30,
    require => File['/etc/logrotate.d/supabase'],
  }

  # Create startup script for manual management
  file { "${supabase::install_directory}/start-supabase.sh":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    content => epp('supabase/start-supabase.sh.epp', {
      docker_dir => $docker_dir,
    }),
    require => File[$supabase::install_directory],
  }

  # Create stop script for manual management
  file { "${supabase::install_directory}/stop-supabase.sh":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    content => epp('supabase/stop-supabase.sh.epp', {
      docker_dir => $docker_dir,
    }),
    require => File[$supabase::install_directory],
  }

  # Create restart script for manual management
  file { "${supabase::install_directory}/restart-supabase.sh":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    content => epp('supabase/restart-supabase.sh.epp', {
      docker_dir => $docker_dir,
    }),
    require => File[$supabase::install_directory],
  }

  # Create logs viewing script
  file { "${supabase::install_directory}/view-logs.sh":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    content => epp('supabase/view-logs.sh.epp', {
      docker_dir => $docker_dir,
    }),
    require => File[$supabase::install_directory],
  }
} 