# Automated Supabase Installation

This directory contains scripts to automatically install and configure Supabase on Ubuntu servers using Puppet.

## Quick Start

### 1. Copy Files to Your Server

```bash
# Copy these files to your server
scp install-supabase.sh config.sh root@your-server:/opt/puppet-supabase/
```

### 2. Edit Configuration

```bash
# On your server, edit the configuration
cd /opt/puppet-supabase
nano config.sh

# Update these critical values:
# - POSTGRES_PASSWORD (make it secure!)
# - JWT_SECRET (40+ characters, secure!)
# - DOMAIN_NAME (your actual domain)
# - DASHBOARD_PASSWORD (secure password)
```

### 3. Run Installation

```bash
# Make scripts executable
chmod +x install-supabase.sh config.sh

# Run the installation (as root)
sudo ./install-supabase.sh
```

### 4. Access Your Supabase

After installation completes (5-10 minutes), access:
- **Studio**: `http://YOUR_SERVER_IP:8000`
- **Username**: From your config.sh
- **Password**: From your config.sh

## Configuration Options

### Basic Setup (config.sh)

```bash
# Required - Change these!
POSTGRES_PASSWORD="your-secure-db-password"
JWT_SECRET="your-40-plus-character-jwt-secret"  
DOMAIN_NAME="supabase.yourdomain.com"
DASHBOARD_USERNAME="admin"
DASHBOARD_PASSWORD="your-secure-dashboard-password"
```

### Advanced Features

```bash
# SSL (enable after DNS is pointing to server)
ENABLE_SSL="true"

# Email/SMTP
SMTP_HOST="smtp.gmail.com"
SMTP_PORT="587" 
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"

# S3 Storage
STORAGE_BACKEND="s3"
S3_BUCKET="your-bucket-name"
S3_REGION="us-east-1"
AWS_ACCESS_KEY_ID="your-access-key"
AWS_SECRET_ACCESS_KEY="your-secret-key"

# Monitoring
ENABLE_MONITORING="true"
```

## What the Script Does

1. ✅ **Installs Dependencies**: Docker, Node.js, Puppet modules
2. ✅ **Generates JWT Tokens**: Creates proper anon and service role keys
3. ✅ **Creates Configuration**: Generates Puppet manifest with your settings
4. ✅ **Deploys Supabase**: Runs Puppet to install and configure everything
5. ✅ **Waits for Services**: Ensures all services are running and healthy
6. ✅ **Shows Access Info**: Displays URLs, credentials, and management commands

## Troubleshooting

### Script Fails

```bash
# Check the last few lines of output for errors
# Common issues:
# - Missing dependencies (script will install them)
# - Invalid configuration (check config.sh)
# - Network connectivity issues

# Retry installation
sudo ./install-supabase.sh
```

### Services Not Starting

```bash
# Check service status
sudo systemctl status supabase

# View logs
sudo journalctl -u supabase -f

# Manual health check
sudo -u supabase /opt/supabase/health-check.sh

# Restart services
sudo systemctl restart supabase
```

### Can't Access Studio

```bash
# Check if services are running
sudo -u supabase /opt/supabase/view-logs.sh

# Check firewall
sudo ufw status

# Test local connectivity
curl http://localhost:8000
```

## Post-Installation Steps

### 1. Test the Installation

1. Access Studio Dashboard: `http://YOUR_SERVER_IP:8000`
2. Login with your credentials
3. Create a test table
4. Verify API access works

### 2. Enable SSL (Production)

```bash
# After DNS is pointing to your server
sudo /opt/supabase/setup-ssl.sh

# Update config.sh
ENABLE_SSL="true"

# Rerun Puppet
sudo ./install-supabase.sh
```

### 3. Set Up Backups

```bash
# Test backup manually
sudo -u supabase /opt/supabase/backup-supabase.sh

# Check backup files
ls -la /opt/supabase/backups/

# Backups run automatically at 2 AM daily
```

### 4. Configure Monitoring (Optional)

```bash
# If enabled, access:
# Grafana: http://YOUR_SERVER_IP:3001 (admin/admin)
# Prometheus: http://YOUR_SERVER_IP:9090
```

## Management Commands

```bash
# Service Management
sudo systemctl status supabase          # Check status
sudo systemctl restart supabase         # Restart
sudo systemctl stop supabase           # Stop
sudo systemctl start supabase          # Start

# Manual Scripts
sudo -u supabase /opt/supabase/start-supabase.sh     # Start services
sudo -u supabase /opt/supabase/stop-supabase.sh      # Stop services
sudo -u supabase /opt/supabase/restart-supabase.sh   # Restart services
sudo -u supabase /opt/supabase/health-check.sh       # Check health
sudo -u supabase /opt/supabase/view-logs.sh          # View logs
sudo -u supabase /opt/supabase/backup-supabase.sh    # Manual backup

# SSL Management (if enabled)
sudo /opt/supabase/setup-ssl.sh         # Initial SSL setup
sudo /opt/supabase/renew-ssl.sh         # Renew certificates
sudo /opt/supabase/check-ssl.sh         # Check certificate status
```

## Automation & Maintenance

### Automated Puppet Runs

The installation script offers to set up a cron job that runs Puppet every 30 minutes to ensure your configuration stays consistent:

```bash
# Setup cron job during installation (prompted automatically)
# Or setup manually after installation:
sudo ./setup-puppet-cron.sh

# Manual Puppet run
sudo /usr/local/bin/puppet-apply-supabase.sh

# View automation logs
tail -f /var/log/puppet/puppet-supabase.log

# View scheduled jobs
sudo cat /etc/crontab | grep puppet

# Disable automation (if needed)
sudo sed -i '/puppet-apply-supabase.sh/d' /etc/crontab
```

### What Automated Runs Do

- ✅ **Configuration Drift**: Corrects any manual changes back to desired state
- ✅ **Service Recovery**: Restarts failed services automatically  
- ✅ **Security Updates**: Ensures firewall rules stay in place
- ✅ **Health Monitoring**: Logs any issues for review
- ✅ **Zero Downtime**: Safe to run while services are active

**Benefits:**
- **Consistency**: Your server always matches your configuration
- **Self-Healing**: Services restart automatically if they fail
- **Audit Trail**: All changes are logged with timestamps
- **Peace of Mind**: Reduces manual maintenance overhead

## Security Notes

⚠️ **Important Security Practices:**

1. **Change Default Passwords**: Never use the example passwords in production
2. **Secure JWT Secret**: Use a random 40+ character string
3. **Enable Firewall**: Only expose necessary ports (80, 443, 22)
4. **Regular Updates**: Keep your system and Supabase updated
5. **Backup Your Data**: Ensure backups are working and tested
6. **Monitor Access**: Review access logs regularly

## File Structure

```
/opt/puppet-supabase/
├── install-supabase.sh    # Main installation script
├── config.sh              # Configuration file (edit this!)
├── manifests/              # Puppet manifests
├── templates/              # Configuration templates
└── examples/               # Example configurations
```

## Getting Help

- **Health Check**: `sudo -u supabase /opt/supabase/health-check.sh`
- **View Logs**: `sudo -u supabase /opt/supabase/view-logs.sh -f`
- **Service Status**: `sudo systemctl status supabase`
- **Configuration**: Check `/opt/supabase/supabase/docker/.env`

---

**🚀 You now have a production-ready Supabase installation!** 