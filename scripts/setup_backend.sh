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

# Create backend directory structure
print_message "Creating backend directory structure..."
mkdir -p /opt/ClassServer/backend/{src/{routes,models,config},logs}

# Create package.json
print_message "Creating package.json..."
cat > /opt/ClassServer/backend/package.json << 'EOF'
{
  "name": "@classserver/backend",
  "version": "1.0.0",
  "description": "ClassServer backend service",
  "main": "src/index.js",
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "@adminjs/express": "^5.1.0",
    "@adminjs/sequelize": "^3.0.0",
    "adminjs": "^6.8.7",
    "cors": "^2.8.5",
    "express": "^4.18.2",
    "express-formidable": "^1.2.0",
    "express-session": "^1.17.3",
    "pg": "^8.11.3",
    "pg-hstore": "^2.3.4",
    "sequelize": "^6.32.1"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}
EOF

# Create adminSetup.js
print_message "Creating adminSetup.js..."
cat > /opt/ClassServer/backend/adminSetup.js << 'EOF'
import AdminJS from 'adminjs';
import AdminJSExpress from '@adminjs/express';
import AdminJSSequelize from '@adminjs/sequelize';
import session from 'express-session';
import { Sequelize } from 'sequelize';

// Register Sequelize adapter
AdminJS.registerAdapter(AdminJSSequelize);

// Create admin credentials - in production, use environment variables
const DEFAULT_ADMIN = {
  email: 'admin@classserver.com',
  password: 'classserver',
};

// Database configuration
const config = {
  username: process.env.DB_USER || 'classserver',
  password: process.env.DB_PASSWORD || 'classserver',
  database: process.env.DB_NAME || 'classserver',
  host: process.env.DB_HOST || 'localhost',
  dialect: 'postgres',
  logging: false
};

// Create Sequelize instance
const sequelize = new Sequelize(
  config.database,
  config.username,
  config.password,
  {
    host: config.host,
    dialect: config.dialect,
    logging: config.logging
  }
);

// Function to initialize AdminJS
const initializeAdmin = async () => {
  try {
    // Test database connection
    await sequelize.authenticate();
    console.log('Database connection established successfully');
    
    // Define AdminJS instance
    const adminJs = new AdminJS({
      databases: [sequelize],
      rootPath: '/admin',
      branding: {
        companyName: 'ClassServer Admin',
        logo: false,
        favicon: '/favicon.ico',
      }
    });

    // Build and export the router
    const router = AdminJSExpress.buildAuthenticatedRouter(
      adminJs,
      {
        authenticate: async (email, password) => {
          if (email === DEFAULT_ADMIN.email && password === DEFAULT_ADMIN.password) {
            return DEFAULT_ADMIN;
          }
          return null;
        },
        cookieName: 'classserver-admin',
        cookiePassword: 'some-secure-secret-password-used-to-sign-cookies',
      },
      null,
      {
        resave: false,
        saveUninitialized: true,
        secret: 'some-secret-key-for-session',
        cookie: {
          httpOnly: process.env.NODE_ENV === 'production',
          secure: process.env.NODE_ENV === 'production',
        },
        name: 'classserver.admin.sid',
      }
    );

    return { adminJs, router };
  } catch (error) {
    console.error('Failed to initialize AdminJS:', error);
    throw error;
  }
};

export { initializeAdmin };
EOF

# Create basic index.js
print_message "Creating src/index.js..."
cat > /opt/ClassServer/backend/src/index.js << 'EOF'
import express from 'express';
import cors from 'cors';
import { initializeAdmin } from '../adminSetup.js';

const app = express();
const PORT = process.env.PORT || 8000;

// Apply CORS middleware
app.use(cors());

// Health check route
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Initialize AdminJS asynchronously
const startServer = async () => {
  try {
    // Initialize AdminJS
    const { router: adminRouter } = await initializeAdmin();
    
    // Mount AdminJS router BEFORE body-parser middleware
    app.use('/admin', adminRouter);
    
    // Apply body-parser middleware AFTER AdminJS router
    app.use(express.json());
    app.use(express.urlencoded({ extended: true }));
    
    // Start server - listen on all network interfaces
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running on port ${PORT} and accessible from network`);
      console.log(`Admin interface available at: http://YOUR_SERVER_IP:${PORT}/admin`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Start the server
startServer();
EOF

# Create database configuration
print_message "Creating database configuration..."
cat > /opt/ClassServer/backend/src/config/database.js << EOF
module.exports = {
  database: process.env.DB_NAME || 'classserver',
  username: process.env.DB_USER || 'classserver',
  password: process.env.DB_PASSWORD || 'classserver',
  host: process.env.DB_HOST || 'localhost',
  dialect: 'postgres',
  logging: false
};
EOF

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
Environment="DATABASE_URL=postgresql://classserver:classserver@localhost/classserver"
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

# Set correct permissions
print_message "Setting correct permissions..."
chown -R www-data:www-data /opt/ClassServer/backend
chmod -R 750 /opt/ClassServer/backend

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

# Verify backend service is running and listening
print_message "Verifying backend service..."
sleep 10  # Give the service some time to start up

# Check if service is active
if ! systemctl is-active --quiet classserver-backend; then
    print_error "Backend service failed to start. Check logs with: sudo journalctl -u classserver-backend"
    exit 1
fi

# Check if service is listening on port 8000
if ! netstat -tulpn | grep -q ":8000"; then
    print_warning "Backend service is running but not listening on port 8000. Check logs with: sudo journalctl -u classserver-backend"
else
    print_message "Backend service is running and listening on port 8000"
fi

print_success "Backend setup completed successfully!" 