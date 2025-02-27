#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Setup Python backend with enhanced error handling
print_message "Setting up Python backend..."
if [ ! -f "/opt/ClassServer/requirements.txt" ]; then
    print_error "requirements.txt not found in /opt/ClassServer"
    print_warning "Please ensure the repository contains a requirements.txt file"
    exit 1
fi

# Create and activate virtual environment with error handling
print_message "Creating Python virtual environment..."
cd /opt/ClassServer || exit 1
if ! python3 -m venv venv; then
    print_error "Failed to create Python virtual environment"
    exit 1
fi

source venv/bin/activate || {
    print_error "Failed to activate Python virtual environment"
    exit 1
}

# Upgrade pip and install dependencies
print_message "Upgrading pip and installing dependencies..."
python -m pip install --upgrade pip || {
    print_error "Failed to upgrade pip"
    exit 1
}

pip install -r /opt/ClassServer/requirements.txt || {
    print_error "Failed to install Python dependencies"
    print_warning "Check requirements.txt for any invalid packages"
    exit 1
}

deactivate

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
Environment="PATH=/opt/ClassServer/venv/bin"
Environment="DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}/${DB_NAME}"
ExecStart=/opt/ClassServer/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
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