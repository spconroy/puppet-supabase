#!/bin/bash

# Minimal Puppet Apply Script
# Installs required modules and applies Puppet configuration

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
MODULE_PATH="${MODULE_PATH:-/opt/puppet-supabase}"
PUPPET_FILE="${PUPPET_FILE:-manifests/setup.pp}"

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

# Install Puppet if not available
if ! command -v puppet &> /dev/null && ! [ -x /opt/puppetlabs/bin/puppet ]; then
    log "Installing Puppet..."
    apt update
    wget https://apt.puppetlabs.com/puppet8-release-$(lsb_release -cs).deb
    dpkg -i puppet8-release-$(lsb_release -cs).deb
    apt update
    apt install -y puppet-agent
    rm -f puppet8-release-*.deb
    success "Puppet installed"
fi

# Set puppet command path
PUPPET_CMD="/opt/puppetlabs/bin/puppet"
if command -v puppet &> /dev/null; then
    PUPPET_CMD="puppet"
fi

log "Installing required Puppet modules..."

# Install Puppet modules
modules=(
    "puppetlabs/stdlib"
    "puppetlabs/docker" 
    "puppetlabs/firewall"
    "puppetlabs/vcsrepo"
    "puppetlabs/apt"
)

for module in "${modules[@]}"; do
    if $PUPPET_CMD module install "$module" --force 2>/dev/null; then
        success "Installed $module"
    else
        warning "$module (already exists or failed)"
    fi
done

success "Puppet modules ready"

# Check if Puppet file exists
if [ ! -f "$PUPPET_FILE" ]; then
    error "Puppet file not found: $PUPPET_FILE"
    echo ""
    echo "Expected locations:"
    echo "  • $PUPPET_FILE"
    echo "  • manifests/setup.pp"
    echo "  • examples/site.pp"
    echo ""
    echo "Or set PUPPET_FILE environment variable:"
    echo "  export PUPPET_FILE=path/to/your/manifest.pp"
    exit 1
fi

log "Applying Puppet configuration: $PUPPET_FILE"

# Apply Puppet configuration
# Create temporary module path structure
temp_modules="/tmp/puppet-modules-$$"
mkdir -p "$temp_modules"
ln -sf "$MODULE_PATH" "$temp_modules/supabase"

if $PUPPET_CMD apply --modulepath="$temp_modules" "$MODULE_PATH/$PUPPET_FILE"; then
    success "Puppet applied successfully!"
    rm -rf "$temp_modules"
    echo ""
    echo "🚀 Services should be starting..."
    echo "   Check status: sudo systemctl status supabase"
    echo "   View logs:    sudo journalctl -u supabase -f"
    echo "   Health check: sudo -u supabase /opt/supabase/health-check.sh"
else
    error "Puppet apply failed!"
    rm -rf "$temp_modules"
    echo ""
    echo "💡 Troubleshooting:"
    echo "   • Check the error messages above"
    echo "   • Verify your manifest syntax: $PUPPET_CMD parser validate $MODULE_PATH/$PUPPET_FILE"
    echo "   • Ensure module path is correct: $MODULE_PATH"
    exit 1
fi 