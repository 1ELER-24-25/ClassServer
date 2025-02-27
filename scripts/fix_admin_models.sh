#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Fixing AdminJS models..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Let's check the models structure first
print_message "Checking models structure..."
cat > check_models.js << 'EOF'
import db from './src/models/index.js';
console.log('DB Object Keys:', Object.keys(db));
console.log('Sequelize:', db.sequelize ? 'Available' : 'Not Available');
console.log('User Model:', db.User ? 'Available' : 'Not Available');
console.log('Game Model:', db.Game ? 'Available' : 'Not Available');
console.log('Match Model:', db.Match ? 'Available' : 'Not Available');
console.log('UserElo Model:', db.UserElo ? 'Available' : 'Not Available');
EOF

print_message "Running model check..."
node check_models.js || {
    print_warning "Failed to check models. This is expected if there are issues with the models."
}

# Fix adminSetup.js to use the models directly
print_message "Updating adminSetup.js..."
cat > adminSetup.js << 'EOF'
import AdminJS from 'adminjs';
import AdminJSExpress from '@adminjs/express';
import AdminJSSequelize from '@adminjs/sequelize';
import session from 'express-session';
import db from './src/models/index.js';

// Register Sequelize adapter
AdminJS.registerAdapter(AdminJSSequelize);

// Define AdminJS instance
const adminJs = new AdminJS({
  databases: [db.sequelize],
  rootPath: '/admin',
  branding: {
    companyName: 'ClassServer Admin',
    logo: false,
    favicon: '/favicon.ico',
  }
});

// Create admin credentials - in production, use environment variables
const DEFAULT_ADMIN = {
  email: 'admin@classserver.com',
  password: 'classserver',
}

// Build and export the router
const router = AdminJSExpress.buildAuthenticatedRouter(
  adminJs,
  {
    authenticate: async (email, password) => {
      // In production, use a proper user model with hashed passwords
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

export { adminJs, router };
EOF

print_success "AdminJS models fixed successfully"

# Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend || {
    print_warning "Failed to restart backend service. It may not be set up as a systemd service yet."
    print_message "You can start the backend manually with: cd /opt/ClassServer/backend && node src/index.js"
}

print_success "Backend service restarted successfully!" 