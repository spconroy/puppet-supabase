# @summary Configure monitoring for Supabase
#
# This class sets up Prometheus monitoring for Supabase services
# and creates dashboards for service health monitoring.
#
class supabase::monitoring {
  $docker_dir = "${supabase::install_directory}/supabase/docker"
  
  # Create monitoring directory
  file { "${supabase::install_directory}/monitoring":
    ensure => directory,
    owner  => 'supabase',
    group  => 'supabase',
    mode   => '0755',
  }

  # Create Prometheus configuration
  file { "${supabase::install_directory}/monitoring/prometheus.yml":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0644',
    content => epp('supabase/prometheus.yml.epp', {
      domain_name => $supabase::domain_name,
    }),
    require => File["${supabase::install_directory}/monitoring"],
  }

  # Create Grafana configuration
  file { "${supabase::install_directory}/monitoring/grafana.ini":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0644',
    content => epp('supabase/grafana.ini.epp'),
    require => File["${supabase::install_directory}/monitoring"],
  }

  # Create monitoring Docker Compose file
  file { "${supabase::install_directory}/monitoring/docker-compose.monitoring.yml":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0644',
    content => epp('supabase/docker-compose.monitoring.yml.epp', {
      install_directory => $supabase::install_directory,
    }),
    require => File["${supabase::install_directory}/monitoring"],
  }

  # Create monitoring startup script
  file { "${supabase::install_directory}/start-monitoring.sh":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    content => epp('supabase/start-monitoring.sh.epp', {
      install_directory => $supabase::install_directory,
    }),
    require => File["${supabase::install_directory}/monitoring"],
  }

  # Create monitoring stop script
  file { "${supabase::install_directory}/stop-monitoring.sh":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    content => epp('supabase/stop-monitoring.sh.epp', {
      install_directory => $supabase::install_directory,
    }),
    require => File["${supabase::install_directory}/monitoring"],
  }

  # Create Grafana dashboard configuration
  file { "${supabase::install_directory}/monitoring/dashboards":
    ensure => directory,
    owner  => 'supabase',
    group  => 'supabase',
    mode   => '0755',
    require => File["${supabase::install_directory}/monitoring"],
  }

  # Create Supabase dashboard JSON
  file { "${supabase::install_directory}/monitoring/dashboards/supabase-dashboard.json":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0644',
    content => file('supabase/supabase-dashboard.json'),
    require => File["${supabase::install_directory}/monitoring/dashboards"],
  }

  # Create alerting rules
  file { "${supabase::install_directory}/monitoring/alert-rules.yml":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0644',
    content => epp('supabase/alert-rules.yml.epp'),
    require => File["${supabase::install_directory}/monitoring"],
  }

  # Create monitoring service file
  file { '/etc/systemd/system/supabase-monitoring.service':
    ensure  => present,
    mode    => '0644',
    content => epp('supabase/supabase-monitoring.service.epp', {
      install_directory => $supabase::install_directory,
    }),
    notify  => Exec['systemd-reload-monitoring'],
  }

  # Reload systemd when service file changes
  exec { 'systemd-reload-monitoring':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  # Start monitoring services
  service { 'supabase-monitoring':
    ensure    => running,
    enable    => true,
    provider  => 'systemd',
    require   => [
      File['/etc/systemd/system/supabase-monitoring.service'],
      Exec['systemd-reload-monitoring'],
    ],
    subscribe => [
      File["${supabase::install_directory}/monitoring/prometheus.yml"],
      File["${supabase::install_directory}/monitoring/grafana.ini"],
      File["${supabase::install_directory}/monitoring/docker-compose.monitoring.yml"],
    ],
  }
} 