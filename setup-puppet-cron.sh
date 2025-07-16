#!/bin/bash

# Setup Puppet Cron Job Script
# Creates a cron job to run puppet apply every 30 minutes

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Configuration
MODULE_PATH="${MODULE_PATH:-/opt/puppet-supabase}"
PUPPET_FILE="${PUPPET_FILE:-manifests/setup.pp}"
LOG_DIR="/var/log/puppet"
PUPPET_CMD="/opt/puppetlabs/bin/puppet"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

echo "========================================"
echo -e "${BLUE}⏰ Puppet Cron Job Setup${NC}"
echo "========================================"
echo ""

log "Setting up automated Puppet runs every 30 minutes..."

# Create log directory
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    success "Created log directory: $LOG_DIR"
fi

# Create the puppet run script
cat > /usr/local/bin/puppet-apply-supabase.sh << EOF
#!/bin/bash

# Automated Puppet Apply Script for Supabase
# This script is run by cron every 30 minutes

set -euo pipefail

# Configuration
MODULE_PATH="$MODULE_PATH"
PUPPET_FILE="$PUPPET_FILE"
LOG_FILE="$LOG_DIR/puppet-supabase.log"
LOCK_FILE="/var/run/puppet-supabase.lock"

# Function to log with timestamp
log_msg() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') \$1" >> "\$LOG_FILE"
}

# Check if another puppet run is in progress
if [ -f "\$LOCK_FILE" ]; then
    # Check if the process is actually running
    if kill -0 "\$(cat \$LOCK_FILE)" 2>/dev/null; then
        log_msg "INFO: Puppet run already in progress (PID: \$(cat \$LOCK_FILE))"
        exit 0
    else
        log_msg "WARN: Removing stale lock file"
        rm -f "\$LOCK_FILE"
    fi
fi

# Create lock file
echo "\$\$" > "\$LOCK_FILE"

# Cleanup function
cleanup() {
    rm -f "\$LOCK_FILE"
}
trap cleanup EXIT

log_msg "INFO: Starting scheduled Puppet run"

# Create temporary module path structure
temp_modules="/tmp/puppet-modules-\$\$"
mkdir -p "\$temp_modules"
ln -sf "\$MODULE_PATH" "\$temp_modules/supabase"

# Run puppet apply
if $PUPPET_CMD apply --modulepath="\$temp_modules:/etc/puppetlabs/code/environments/production/modules" "\$MODULE_PATH/\$PUPPET_FILE" >> "\$LOG_FILE" 2>&1; then
    log_msg "SUCCESS: Puppet run completed successfully"
    exit_code=0
else
    log_msg "ERROR: Puppet run failed (exit code: \$?)"
    exit_code=1
fi

# Cleanup temporary files
rm -rf "\$temp_modules"

# Rotate log file if it gets too large (> 10MB)
if [ -f "\$LOG_FILE" ] && [ \$(stat -c%s "\$LOG_FILE") -gt 10485760 ]; then
    mv "\$LOG_FILE" "\$LOG_FILE.old"
    log_msg "INFO: Log file rotated"
fi

exit \$exit_code
EOF

# Make the script executable
chmod +x /usr/local/bin/puppet-apply-supabase.sh
success "Created Puppet run script: /usr/local/bin/puppet-apply-supabase.sh"

# Create the cron job
cron_entry="*/30 * * * * root /usr/local/bin/puppet-apply-supabase.sh"

# Check if cron job already exists
if grep -qF "puppet-apply-supabase.sh" /etc/crontab 2>/dev/null; then
    warning "Cron job already exists in /etc/crontab"
    
    # Show existing entry
    echo "Existing entry:"
    grep "puppet-apply-supabase.sh" /etc/crontab
    echo ""
    
    read -p "Do you want to replace it? (y/N): " replace
    if [[ $replace =~ ^[Yy]$ ]]; then
        # Remove existing entry
        sed -i '/puppet-apply-supabase.sh/d' /etc/crontab
        log "Removed existing cron job"
    else
        log "Keeping existing cron job"
        exit 0
    fi
fi

# Add new cron job
echo "$cron_entry" >> /etc/crontab
success "Added cron job to run Puppet every 30 minutes"

# Restart cron service to pick up changes
systemctl restart cron 2>/dev/null || systemctl restart crond 2>/dev/null || service cron restart
success "Restarted cron service"

# Create initial log entry
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: Puppet cron job setup completed" >> "$LOG_DIR/puppet-supabase.log"

echo ""
echo "========================================"
echo -e "${GREEN}✅ Cron Job Setup Complete!${NC}"
echo "========================================"
echo ""
echo "📋 Configuration:"
echo "  • Frequency: Every 30 minutes"
echo "  • Script: /usr/local/bin/puppet-apply-supabase.sh" 
echo "  • Log file: $LOG_DIR/puppet-supabase.log"
echo "  • Module path: $MODULE_PATH"
echo "  • Manifest: $PUPPET_FILE"
echo ""
echo "🔧 Management commands:"
echo "  • View cron jobs: crontab -l"
echo "  • View system cron: cat /etc/crontab | grep puppet"
echo "  • Check logs: tail -f $LOG_DIR/puppet-supabase.log"
echo "  • Manual run: sudo /usr/local/bin/puppet-apply-supabase.sh"
echo "  • Disable cron: sudo sed -i '/puppet-apply-supabase.sh/d' /etc/crontab"
echo ""
echo "📊 Next scheduled run: $(date -d '+30 minutes' '+%Y-%m-%d %H:%M')"
echo ""

success "Puppet automation setup completed!" 