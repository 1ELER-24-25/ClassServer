#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Get server address for API configuration
SERVER_ADDRESS=$(get_server_address)

# Create frontend directory structure
print_message "Creating frontend directory structure..."
mkdir -p /opt/ClassServer/frontend/src/{components,hooks,pages,types,utils}

# Copy frontend files from repository
print_message "Copying frontend files..."
cp -r "$(dirname "$SCRIPT_DIR")/frontend/"* /opt/ClassServer/frontend/

# Create .env file for Vite
print_message "Creating frontend environment configuration..."
cat > /opt/ClassServer/frontend/.env << EOF
VITE_API_URL=http://${SERVER_ADDRESS}/api
EOF

# Install frontend dependencies
print_message "Installing frontend dependencies..."
cd /opt/ClassServer/frontend
npm install || {
    print_error "Failed to install frontend dependencies"
    exit 1
}

# Build frontend
print_message "Building frontend..."
npm run build || {
    print_error "Failed to build frontend"
    exit 1
}

# Set permissions
print_message "Setting frontend permissions..."
chown -R www-data:www-data /opt/ClassServer/frontend/dist

print_message "Frontend setup completed successfully!" 