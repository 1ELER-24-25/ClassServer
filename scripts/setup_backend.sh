#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Setup Node.js backend
print_message "Setting up Node.js backend..."

# Navigate to the backend directory
cd /opt/ClassServer/backend || {
    print_error "Failed to navigate to backend directory"
    exit 1
}

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
cat > /etc/systemd/system/classserver-backend.service << EOF
[Unit]
Description=ClassServer Backend
After=network.target postgresql.service
Requires=postgresql.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/ClassServer/backend
Environment="DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}/${DB_NAME}"
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=5
StartLimitIntervalSec=60
StartLimitBurst=3

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=full
ProtectHome=yes
CapabilityBoundingSet=
AmbientCapabilities=
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
LockPersonality=yes

[Install]
WantedBy=multi-user.target
EOF

# Start and enable backend service
print_message "Starting backend service..."
systemctl daemon-reload || {
    print_error "Failed to reload systemd configuration"
    exit 1
}

systemctl enable classserver-backend || {
    print_error "Failed to enable backend service"
    exit 1
}

systemctl start classserver-backend || {
    print_error "Failed to start backend service"
    exit 1
}

print_message "Backend setup completed successfully!" 