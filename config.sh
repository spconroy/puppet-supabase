#!/bin/bash

# Supabase Configuration File
# Edit these values for your specific setup before running install-supabase.sh

# =============================================================================
# BASIC CONFIGURATION (Required)
# =============================================================================

# PostgreSQL database password (make this secure!)
export POSTGRES_PASSWORD="Trouble-Else-Wake-Shorten-6"

# JWT secret for token signing (40+ characters, make this secure!)
export JWT_SECRET="Wash-Basic-Letter-Run-Whistle-Try-Shout-4-Extended"

# Your domain name (where Supabase will be accessible)
export DOMAIN_NAME="supabase.inventivehq.com"

# Dashboard login credentials
export DASHBOARD_USERNAME="admin"
export DASHBOARD_PASSWORD="Trouble-Else-Wake-Shorten-6"

# =============================================================================
# INSTALLATION PATHS
# =============================================================================

# Where the Puppet module is located
export MODULE_PATH="/opt/puppet-supabase"

# =============================================================================
# OPTIONAL CONFIGURATION (Advanced)
# =============================================================================

# SSL Configuration (set to true once DNS is pointing to your server)
export ENABLE_SSL="false"

# Backup settings
export ENABLE_BACKUPS="true"
export BACKUP_RETENTION_DAYS="7"

# Email/SMTP settings (leave empty to disable email features)
export SMTP_HOST=""
export SMTP_PORT=""
export SMTP_USER=""
export SMTP_PASS=""
export SMTP_ADMIN_EMAIL=""

# Storage settings (file or s3)
export STORAGE_BACKEND="file"

# S3 settings (only needed if STORAGE_BACKEND="s3")
export S3_BUCKET=""
export S3_REGION=""
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""

# Application URLs
export SITE_URL="https://${DOMAIN_NAME}"
export ADDITIONAL_REDIRECT_URLS="http://localhost:3000,https://app.${DOMAIN_NAME}"

# Monitoring (set to true to enable Prometheus/Grafana)
export ENABLE_MONITORING="false"

# =============================================================================
# SECURITY RECOMMENDATIONS
# =============================================================================

echo "⚠️  SECURITY CHECKLIST:"
echo "   1. Change POSTGRES_PASSWORD to a strong, unique password"
echo "   2. Change JWT_SECRET to a random 40+ character string"
echo "   3. Change DASHBOARD_PASSWORD to a strong password"
echo "   4. Update DOMAIN_NAME to your actual domain"
echo "   5. Keep these credentials secure and never commit to version control"
echo ""
echo "📝 To generate secure passwords/secrets:"
echo "   openssl rand -base64 32        # For passwords"  
echo "   openssl rand -base64 48        # For JWT secret"
echo ""
echo "🚀 After editing this file, run: sudo ./install-supabase.sh" 