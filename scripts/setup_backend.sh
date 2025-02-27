#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Get the user's home directory
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})

# Setup Node.js backend
print_message "Setting up Node.js backend..."

# Ensure the repository is properly copied to /opt/ClassServer
print_message "Ensuring repository is properly copied to /opt/ClassServer..."
if [ ! -d "/opt/ClassServer" ]; then
    print_message "Creating /opt/ClassServer directory..."
    mkdir -p /opt/ClassServer
fi

# Copy repository files if they don't exist
if [ ! -d "/opt/ClassServer/backend" ]; then
    print_message "Copying repository files to /opt/ClassServer..."
    if [ -d "${USER_HOME}/ClassServer" ]; then
        cp -r ${USER_HOME}/ClassServer/* /opt/ClassServer/
    else
        print_error "Source directory ${USER_HOME}/ClassServer not found"
        exit 1
    fi
fi

# Create backend directory if it doesn't exist
if [ ! -d "/opt/ClassServer/backend" ]; then
    print_message "Creating backend directory..."
    mkdir -p /opt/ClassServer/backend
    
    # If backend directory still doesn't exist after copying, create a basic structure
    print_message "Creating basic Node.js project structure..."
    cd /opt/ClassServer/backend
    
    # Create a basic package.json if it doesn't exist
    if [ ! -f "package.json" ]; then
        cat > package.json << EOF
{
  "name": "classserver-backend",
  "version": "1.0.0",
  "description": "ClassServer Backend",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3",
    "sequelize": "^6.35.1",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1"
  }
}
EOF
    fi
    
    # Create a basic index.js if it doesn't exist
    if [ ! -f "index.js" ]; then
        cat > index.js << EOF
const express = require('express');
const cors = require('cors');
const app = express();
const port = process.env.PORT || 8000;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: 'ClassServer API is running' });
});

app.listen(port, () => {
  console.log(\`Server running on port \${port}\`);
});
EOF
    fi
else
    # Navigate to the backend directory
    cd /opt/ClassServer/backend || {
        print_error "Failed to navigate to backend directory"
        exit 1
    }
fi

# Install Node.js dependencies
print_message "Installing Node.js dependencies..."
if ! npm install; then
    print_error "Failed to install Node.js dependencies"
    exit 1
fi

# Create config directory if it doesn't exist
if [ ! -d "/opt/ClassServer/config" ]; then
    print_message "Creating config directory..."
    mkdir -p /opt/ClassServer/config
    
    # Create a basic database.env file if it doesn't exist
    if [ ! -f "/opt/ClassServer/config/database.env" ]; then
        cat > /opt/ClassServer/config/database.env << EOF
DB_HOST=localhost
DB_NAME=classserver
DB_USER=classserver
DB_PASSWORD=classserver
EOF
    fi
fi

# Load database configuration
if [ -f "/opt/ClassServer/config/database.env" ]; then
    source /opt/ClassServer/config/database.env
else
    print_warning "Database configuration file not found, using default values"
    DB_HOST=localhost
    DB_NAME=classserver
    DB_USER=classserver
    DB_PASSWORD=classserver
fi

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

# Setup AdminJS admin panel
print_message "Setting up AdminJS admin panel..."
"$SCRIPT_DIR/setup_admin.sh"

print_message "Backend setup completed successfully!" 