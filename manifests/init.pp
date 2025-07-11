# @summary Install and configure Supabase on Ubuntu
#
# This class installs and configures a production-ready Supabase instance
# using Docker Compose on Ubuntu servers.
#
# @param supabase_version
#   Version of Supabase to install (git branch/tag)
# @param install_directory
#   Directory where Supabase will be installed
# @param postgres_password
#   PostgreSQL database password
# @param jwt_secret
#   JWT secret for token signing (40+ character string)
# @param anon_key
#   Supabase anonymous API key
# @param service_role_key
#   Supabase service role API key
# @param site_url
#   Primary site URL for your application
# @param additional_redirect_urls
#   Additional URLs for authentication redirects
# @param dashboard_username
#   Username for Supabase Studio dashboard
# @param dashboard_password
#   Password for Supabase Studio dashboard
# @param domain_name
#   Domain name for your Supabase instance
# @param enable_ssl
#   Whether to enable SSL/TLS with Let's Encrypt
# @param smtp_host
#   SMTP server hostname for email
# @param smtp_port
#   SMTP server port
# @param smtp_user
#   SMTP username
# @param smtp_pass
#   SMTP password
# @param smtp_admin_email
#   Admin email address for SMTP
# @param storage_backend
#   Storage backend ('file' or 's3')
# @param s3_bucket
#   S3 bucket name (if using S3 storage)
# @param s3_region
#   S3 region (if using S3 storage)
# @param s3_endpoint
#   S3 endpoint URL (if using S3-compatible storage)
# @param aws_access_key_id
#   AWS access key ID (if using S3 storage)
# @param aws_secret_access_key
#   AWS secret access key (if using S3 storage)
# @param enable_backups
#   Whether to enable automated database backups
# @param backup_retention_days
#   Number of days to retain backups
# @param enable_monitoring
#   Whether to enable Prometheus monitoring
# @param docker_compose_version
#   Version of Docker Compose to install
#
# @example Basic installation
#   class { 'supabase':
#     postgres_password    => 'secure_password_123',
#     jwt_secret          => 'your-super-secret-jwt-token-with-at-least-32-characters',
#     anon_key            => 'generated_anon_key',
#     service_role_key    => 'generated_service_role_key',
#     domain_name         => 'supabase.example.com',
#     dashboard_username  => 'admin',
#     dashboard_password  => 'secure_dashboard_password',
#   }
#
# @example With custom storage and SMTP
#   class { 'supabase':
#     postgres_password    => 'secure_password_123',
#     jwt_secret          => 'your-super-secret-jwt-token-with-at-least-32-characters',
#     anon_key            => 'generated_anon_key',
#     service_role_key    => 'generated_service_role_key',
#     domain_name         => 'supabase.example.com',
#     storage_backend     => 's3',
#     s3_bucket          => 'my-supabase-bucket',
#     s3_region          => 'us-east-1',
#     smtp_host          => 'smtp.gmail.com',
#     smtp_port          => 587,
#     smtp_user          => 'user@example.com',
#     smtp_pass          => 'smtp_password',
#     smtp_admin_email   => 'admin@example.com',
#   }
#
class supabase (
  String $postgres_password,
  String $jwt_secret,
  String $anon_key,
  String $service_role_key,
  String $domain_name,
  String $dashboard_username = 'supabase',
  String $dashboard_password = 'changeme',
  String $supabase_version = 'main',
  Stdlib::Absolutepath $install_directory = '/opt/supabase',
  String $site_url = "https://${domain_name}",
  Array[String] $additional_redirect_urls = ["http://localhost:3000"],
  Boolean $enable_ssl = true,
  Optional[String] $smtp_host = undef,
  Optional[Integer] $smtp_port = undef,
  Optional[String] $smtp_user = undef,
  Optional[String] $smtp_pass = undef,
  Optional[String] $smtp_admin_email = undef,
  Enum['file', 's3'] $storage_backend = 'file',
  Optional[String] $s3_bucket = undef,
  Optional[String] $s3_region = undef,
  Optional[String] $s3_endpoint = undef,
  Optional[String] $aws_access_key_id = undef,
  Optional[String] $aws_secret_access_key = undef,
  Boolean $enable_backups = true,
  Integer $backup_retention_days = 7,
  Boolean $enable_monitoring = false,
  String $docker_compose_version = '2.24.0',
) {

  # Validate parameters
  if length($jwt_secret) < 32 {
    fail('jwt_secret must be at least 32 characters long')
  }

  if $storage_backend == 's3' {
    if !$s3_bucket or !$s3_region {
      fail('s3_bucket and s3_region are required when storage_backend is s3')
    }
  }

  # Ensure classes are applied in the correct order
  contain supabase::install
  contain supabase::config
  contain supabase::service

  Class['supabase::install']
  -> Class['supabase::config']
  -> Class['supabase::service']

  # Optional components
  if $enable_ssl {
    contain supabase::ssl
    Class['supabase::service'] -> Class['supabase::ssl']
  }

  if $enable_backups {
    contain supabase::backup
    Class['supabase::service'] -> Class['supabase::backup']
  }

  if $enable_monitoring {
    contain supabase::monitoring
    Class['supabase::service'] -> Class['supabase::monitoring']
  }
} 