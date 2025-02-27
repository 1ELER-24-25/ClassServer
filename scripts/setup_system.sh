#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Update system
print_message "Updating system packages..."
apt-get update || {
    print_error "Failed to update package list"
    exit 1
}
apt-get upgrade -y || {
    print_error "Failed to upgrade packages"
    exit 1
}

# Install required packages
print_message "Installing required packages..."
apt-get install -y \
    postgresql \
    nginx \
    python3-pip \
    python3-venv \
    git \
    ufw || {
    print_error "Failed to install required packages"
    exit 1
}

# Install Node.js 20.x
print_message "Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - || {
    print_error "Failed to setup Node.js repository"
    exit 1
}
apt-get install -y nodejs || {
    print_error "Failed to install Node.js"
    exit 1
}

# Configure firewall
print_message "Configuring firewall..."
ufw status verbose | grep -q "Status: active" && {
    print_warning "Firewall is already active. Adding rules..."
} || {
    print_message "Enabling firewall..."
    ufw --force enable
}

ufw allow 80/tcp || {
    print_error "Failed to add HTTP firewall rule"
    exit 1
}
ufw allow OpenSSH || {
    print_error "Failed to add SSH firewall rule"
    exit 1
}

print_message "System setup completed successfully!" 