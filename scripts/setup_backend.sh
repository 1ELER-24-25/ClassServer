#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Setup Node.js backend
print_message "Setting up Node.js backend..."

# Navigate to the backend directory
cd /opt/ClassServer || exit 1

# Install Node.js dependencies
print_message "Installing Node.js dependencies..."
if ! npm install; then
    print_error "Failed to install Node.js dependencies"
    exit 1
fi

# Load database configuration
source /opt/ClassServer/config/database.env

# Create backend service with enhanced security
print_message "Creating backend service..."
# Add commands to set up the Node.js service, e.g., using systemd 