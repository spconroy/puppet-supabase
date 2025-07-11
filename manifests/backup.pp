# @summary Configure automated backups for Supabase
#
# This class sets up automated database backups for Supabase PostgreSQL
# with rotation and retention policies.
#
class supabase::backup {
  $docker_dir = "${supabase::install_directory}/supabase/docker"
  $backup_dir = "${supabase::install_directory}/backups"

  # Create backup script
  file { "${supabase::install_directory}/backup-supabase.sh":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    content => epp('supabase/backup-supabase.sh.epp', {
      docker_dir           => $docker_dir,
      backup_dir           => $backup_dir,
      retention_days       => $supabase::backup_retention_days,
      postgres_password    => $supabase::postgres_password,
    }),
    require => File[$backup_dir],
  }

  # Create backup cleanup script
  file { "${supabase::install_directory}/cleanup-backups.sh":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    content => epp('supabase/cleanup-backups.sh.epp', {
      backup_dir     => $backup_dir,
      retention_days => $supabase::backup_retention_days,
    }),
    require => File[$backup_dir],
  }

  # Schedule daily backups at 2 AM
  cron { 'supabase-daily-backup':
    command => "${supabase::install_directory}/backup-supabase.sh",
    user    => 'supabase',
    hour    => 2,
    minute  => 0,
    require => File["${supabase::install_directory}/backup-supabase.sh"],
  }

  # Schedule backup cleanup to run daily at 3 AM
  cron { 'supabase-backup-cleanup':
    command => "${supabase::install_directory}/cleanup-backups.sh",
    user    => 'supabase',
    hour    => 3,
    minute  => 0,
    require => File["${supabase::install_directory}/cleanup-backups.sh"],
  }

  # Create restore script for emergencies
  file { "${supabase::install_directory}/restore-supabase.sh":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    content => epp('supabase/restore-supabase.sh.epp', {
      docker_dir        => $docker_dir,
      backup_dir        => $backup_dir,
      postgres_password => $supabase::postgres_password,
    }),
    require => File[$backup_dir],
  }

  # Create backup verification script
  file { "${supabase::install_directory}/verify-backup.sh":
    ensure  => present,
    owner   => 'supabase',
    group   => 'supabase',
    mode    => '0755',
    content => epp('supabase/verify-backup.sh.epp', {
      backup_dir => $backup_dir,
    }),
    require => File[$backup_dir],
  }
} 