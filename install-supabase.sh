#!/bin/bash

# Supabase Installation Script
# This script automates the complete setup of Supabase using Puppet

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Load configuration from config.sh if it exists
if [ -f "$(dirname "$0")/config.sh" ]; then
    log "Loading configuration from config.sh..."
    source "$(dirname "$0")/config.sh"
else
    # Default configuration - Update these values for your setup
    POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-Trouble-Else-Wake-Shorten-6}"
    JWT_SECRET="${JWT_SECRET:-Wash-Basic-Letter-Run-Whistle-Try-Shout-4-Extended}"
    DOMAIN_NAME="${DOMAIN_NAME:-supabase.inventivehq.com}"
    DASHBOARD_USERNAME="${DASHBOARD_USERNAME:-admin}"
    DASHBOARD_PASSWORD="${DASHBOARD_PASSWORD:-Trouble-Else-Wake-Shorten-6}"
    MODULE_PATH="${MODULE_PATH:-/opt/puppet-supabase}"
fi

# Set additional defaults for optional parameters
ENABLE_SSL="${ENABLE_SSL:-false}"
ENABLE_BACKUPS="${ENABLE_BACKUPS:-true}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
STORAGE_BACKEND="${STORAGE_BACKEND:-file}"
ENABLE_MONITORING="${ENABLE_MONITORING:-false}"
SETUP_CRON="${SETUP_CRON:-true}"



# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Install required packages
install_packages() {
    log "Installing required packages..."
    
    apt update
    apt install -y curl wget python3 python3-pip jq
    
    # Install Puppet if not already installed
    if ! command -v puppet &> /dev/null; then
        log "Installing Puppet..."
        wget https://apt.puppetlabs.com/puppet8-release-$(lsb_release -cs).deb
        dpkg -i puppet8-release-$(lsb_release -cs).deb
        apt update
        apt install -y puppet-agent
        
        # Add Puppet to PATH
        echo 'export PATH="/opt/puppetlabs/bin:$PATH"' >> /etc/environment
        export PATH="/opt/puppetlabs/bin:$PATH"
        
        rm -f puppet8-release-*.deb
        success "Puppet installed"
    else
        success "Puppet already installed"
    fi
    
    # Install Node.js for JWT generation (if not already installed)
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt install -y nodejs
    fi
    
    success "Required packages installed"
}

# Install Puppet modules
install_puppet_modules() {
    log "Installing required Puppet modules..."
    
    local modules=(
        "puppetlabs/stdlib"
        "puppetlabs/docker"
        "puppetlabs/firewall"
        "puppetlabs/vcsrepo"
        "puppetlabs/apt"
    )
    
    for module in "${modules[@]}"; do
        log "Installing $module..."
        if /opt/puppetlabs/bin/puppet module install "$module" --force; then
            success "Installed $module"
        else
            warning "Failed to install $module (may already exist)"
        fi
    done
    
    success "Puppet modules installation completed"
}

# Generate JWT tokens
generate_jwt_tokens() {
    log "Generating JWT tokens..."
    
    # Create a temporary Node.js script to generate JWT tokens
    cat > /tmp/generate_jwt.js << 'EOF'
const crypto = require('crypto');

function base64UrlEscape(str) {
    return str.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

function base64UrlEncode(str) {
    return base64UrlEscape(Buffer.from(str).toString('base64'));
}

function hmacSign(message, secret) {
    return base64UrlEscape(crypto.createHmac('sha256', secret).update(message).digest('base64'));
}

function generateJWT(payload, secret) {
    const header = {
        "alg": "HS256",
        "typ": "JWT"
    };
    
    const encodedHeader = base64UrlEncode(JSON.stringify(header));
    const encodedPayload = base64UrlEncode(JSON.stringify(payload));
    const signature = hmacSign(`${encodedHeader}.${encodedPayload}`, secret);
    
    return `${encodedHeader}.${encodedPayload}.${signature}`;
}

const secret = process.argv[2];
const now = Math.floor(Date.now() / 1000);
const exp = now + (20 * 365 * 24 * 60 * 60); // 20 years from now

const anonPayload = {
    "iss": "supabase",
    "ref": "anon",
    "role": "anon",
    "iat": now,
    "exp": exp
};

const servicePayload = {
    "iss": "supabase",
    "ref": "service_role",
    "role": "service_role",
    "iat": now,
    "exp": exp
};

console.log("ANON_KEY=" + generateJWT(anonPayload, secret));
console.log("SERVICE_ROLE_KEY=" + generateJWT(servicePayload, secret));
EOF

    # Generate the tokens
    local tokens
    tokens=$(node /tmp/generate_jwt.js "$JWT_SECRET")
    
    # Extract tokens
    ANON_KEY=$(echo "$tokens" | grep "ANON_KEY=" | cut -d'=' -f2)
    SERVICE_ROLE_KEY=$(echo "$tokens" | grep "SERVICE_ROLE_KEY=" | cut -d'=' -f2)
    
    # Clean up
    rm /tmp/generate_jwt.js
    
    success "JWT tokens generated successfully"
    log "Anon Key: ${ANON_KEY:0:50}..."
    log "Service Role Key: ${SERVICE_ROLE_KEY:0:50}..."
}

# Create or update the Puppet configuration
create_puppet_config() {
    log "Creating Puppet configuration..."
    
    local hostname
    hostname=$(hostname -f)
    
    cat > "${MODULE_PATH}/manifests/setup.pp" << EOF
node '$hostname' {
  class { 'supabase':
    postgres_password    => '$POSTGRES_PASSWORD',
    jwt_secret          => '$JWT_SECRET',
    anon_key            => '$ANON_KEY',
    service_role_key    => '$SERVICE_ROLE_KEY',
    domain_name         => '$DOMAIN_NAME',
    dashboard_username  => '$DASHBOARD_USERNAME',
    dashboard_password  => '$DASHBOARD_PASSWORD',
    
    # Configuration from config.sh
    enable_ssl          => $ENABLE_SSL,
    enable_backups      => $ENABLE_BACKUPS,
    backup_retention_days => $BACKUP_RETENTION_DAYS,
    storage_backend     => '$STORAGE_BACKEND',
    enable_monitoring   => $ENABLE_MONITORING,$(
    if [ -n "$SMTP_HOST" ]; then
        cat << SMTP_EOF
    
    # SMTP Configuration
    smtp_host           => '$SMTP_HOST',
    smtp_port           => $SMTP_PORT,
    smtp_user           => '$SMTP_USER',
    smtp_pass           => '$SMTP_PASS',
    smtp_admin_email    => '$SMTP_ADMIN_EMAIL',
SMTP_EOF
    fi
    )$(
    if [ "$STORAGE_BACKEND" = "s3" ] && [ -n "$S3_BUCKET" ]; then
        cat << S3_EOF
    
    # S3 Storage Configuration  
    s3_bucket           => '$S3_BUCKET',
    s3_region           => '$S3_REGION',
    aws_access_key_id   => '$AWS_ACCESS_KEY_ID',
    aws_secret_access_key => '$AWS_SECRET_ACCESS_KEY',
S3_EOF
    fi
    )
  }
}
EOF
    
    success "Puppet configuration created at ${MODULE_PATH}/manifests/setup.pp"
}

# Run Puppet apply
run_puppet() {
    log "Applying Puppet configuration..."
    
    # Create a temporary symlink structure for Puppet module path
    local temp_modules="/tmp/puppet-modules-$$"
    mkdir -p "$temp_modules"
    ln -sf "$MODULE_PATH" "$temp_modules/supabase"
    
    if /opt/puppetlabs/bin/puppet apply --modulepath="$temp_modules:/etc/puppetlabs/code/environments/production/modules" "$MODULE_PATH/manifests/setup.pp"; then
        success "Puppet configuration applied successfully!"
        rm -rf "$temp_modules"
    else
        error "Puppet configuration failed. Check the logs above."
        rm -rf "$temp_modules"
        return 1
    fi
}

# Wait for services to be ready
wait_for_services() {
    log "Waiting for Supabase services to start..."
    
    local max_wait=300
    local count=0
    
    while [ $count -lt $max_wait ]; do
        if curl -s -f "http://localhost:8000/health" > /dev/null 2>&1; then
            success "Supabase services are running!"
            return 0
        fi
        
        sleep 10
        count=$((count + 10))
        log "Still waiting for services... (${count}s elapsed)"
    done
    
    warning "Services didn't start within ${max_wait} seconds. Check manually with:"
    echo "  sudo -u supabase /opt/supabase/health-check.sh"
}

# Display final information
show_final_info() {
    echo ""
    echo "========================================"
    echo -e "${GREEN}🎉 Supabase Installation Complete!${NC}"
    echo "========================================"
    echo ""
    echo "📊 Access Information:"
    echo "  • Studio Dashboard: http://$(hostname -I | awk '{print $1}'):8000"
    echo "  • Username: $DASHBOARD_USERNAME"
    echo "  • Password: $DASHBOARD_PASSWORD"
    echo ""
    echo "🔑 API Configuration:"
    echo "  • API URL: http://$(hostname -I | awk '{print $1}'):8000"
    echo "  • Anon Key: $ANON_KEY"
    echo "  • Service Role Key: $SERVICE_ROLE_KEY"
    echo ""
    echo "🛠️  Management Commands:"
    echo "  • Check status: sudo systemctl status supabase"
    echo "  • View logs: sudo journalctl -u supabase -f"
    echo "  • Health check: sudo -u supabase /opt/supabase/health-check.sh"
    echo "  • Start services: sudo -u supabase /opt/supabase/start-supabase.sh"
    echo "  • Stop services: sudo -u supabase /opt/supabase/stop-supabase.sh"
    echo ""
    echo "📚 Next Steps:"
    echo "  1. Test the installation by accessing the Studio Dashboard"
    echo "  2. Create your first project/database tables"
    echo "  3. Configure SSL: sudo /opt/supabase/setup-ssl.sh (if domain DNS is ready)"
    echo "  4. Set up SMTP for email authentication (optional)"
    echo ""
    echo "🔧 Configuration File: ${MODULE_PATH}/manifests/setup.pp"
    echo ""
}

# Main execution
main() {
    echo "========================================"
    echo -e "${BLUE}🚀 Supabase Installation Script${NC}"
    echo "========================================"
    echo ""
    
    log "Starting Supabase installation..."
    log "Module Path: $MODULE_PATH"
    log "Domain: $DOMAIN_NAME"
    
    check_root
    install_packages
    install_puppet_modules
    generate_jwt_tokens
    create_puppet_config
    run_puppet
    wait_for_services
    show_final_info
    
    success "Installation completed successfully!"
}

# Handle script interruption
trap 'error "Installation interrupted!"; exit 1' INT TERM

# Run the main function
main "$@" 