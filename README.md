# Puppet Supabase Module

A comprehensive Puppet module for installing and configuring Supabase on Ubuntu servers.

## Features

- Complete Supabase installation with Docker Compose
- SSL/TLS with Let's Encrypt
- Automated backups and monitoring
- Production-ready security settings
- Health checks and operational scripts

## Requirements

- Ubuntu 20.04, 22.04, or 24.04 LTS
- Minimum 4GB RAM, 2 CPU cores
- Puppet 6.0.0 or higher
- Domain name (for SSL)

## Quick Start

1. Generate API keys using the Supabase JWT Generator
2. Create a Puppet manifest:

```puppet
class { 'supabase':
  postgres_password    => 'secure-db-password',
  jwt_secret          => 'your-40-char-jwt-secret',
  anon_key            => 'your-anon-key',
  service_role_key    => 'your-service-role-key',
  domain_name         => 'supabase.example.com',
  dashboard_username  => 'admin',
  dashboard_password  => 'secure-password',
}
```

3. Apply with `puppet apply site.pp`

## Configuration Options

### Required Parameters

- `postgres_password`: Database password
- `jwt_secret`: JWT secret (40+ characters)
- `anon_key`: Anonymous API key
- `service_role_key`: Service role API key
- `domain_name`: Your domain name

### Optional Parameters

- `enable_ssl`: Enable SSL (default: true)
- `enable_backups`: Enable backups (default: true)
- `storage_backend`: 'file' or 's3' (default: 'file')
- `smtp_host`: SMTP server for email
- `enable_monitoring`: Enable Prometheus monitoring

## After Installation

1. Access Studio: `https://studio.yourdomain.com`
2. API endpoint: `https://api.yourdomain.com`
3. Setup SSL: `sudo /opt/supabase/setup-ssl.sh`

## Management Scripts

- Health check: `/opt/supabase/health-check.sh`
- Backup: `/opt/supabase/backup-supabase.sh`
- Start/stop: `/opt/supabase/start-supabase.sh`
- View logs: `/opt/supabase/view-logs.sh`

## Troubleshooting

- Check service: `sudo systemctl status supabase`
- View logs: `sudo journalctl -u supabase -f`
- Health check: `sudo -u supabase /opt/supabase/health-check.sh`

For detailed documentation, see the module files and templates.

## Automated Installation

For a completely automated setup, use the installation scripts:

1. **Copy files to your server**:
   ```bash
   scp -r /path/to/puppet-supabase root@your-server:/opt/
   ```

2. **Edit configuration**:
   ```bash
   cd /opt/puppet-supabase
   nano config.sh  # Update passwords, domain, etc.
   ```

3. **Run installation**:
   ```bash
   sudo ./install-supabase.sh
   ```

See [INSTALL.md](INSTALL.md) for complete automated installation instructions. 