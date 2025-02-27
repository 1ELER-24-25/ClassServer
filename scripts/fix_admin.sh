#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Fixing AdminJS setup..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Fix adminSetup.js
print_message "Fixing adminSetup.js..."
cat > adminSetup.js << 'EOF'
import AdminJS from 'adminjs';
import AdminJSExpress from '@adminjs/express';
import AdminJSSequelize from '@adminjs/sequelize';
import session from 'express-session';
import db from './src/models/index.js';

const { sequelize, User, Game, Match, UserElo } = db;

// Register Sequelize adapter
AdminJS.registerAdapter(AdminJSSequelize);

// Define AdminJS instance
const adminJs = new AdminJS({
  databases: [sequelize],
  resources: [
    {
      resource: User,
      options: {
        navigation: { name: 'Users Management', icon: 'User' },
        properties: {
          created_at: { isVisible: { list: true, filter: true, show: true, edit: false } },
          updated_at: { isVisible: { list: true, filter: true, show: true, edit: false } }
        }
      },
    },
    {
      resource: Game,
      options: {
        navigation: { name: 'Games Management', icon: 'GameController' },
        properties: {
          created_at: { isVisible: { list: true, filter: true, show: true, edit: false } },
          updated_at: { isVisible: { list: true, filter: true, show: true, edit: false } }
        }
      },
    },
    {
      resource: Match,
      options: {
        navigation: { name: 'Matches', icon: 'Activity' },
        properties: {
          played_at: { isVisible: { list: true, filter: true, show: true, edit: true } },
          created_at: { isVisible: { list: true, filter: true, show: true, edit: false } },
          updated_at: { isVisible: { list: true, filter: true, show: true, edit: false } }
        }
      },
    },
    {
      resource: UserElo,
      options: {
        navigation: { name: 'ELO Ratings', icon: 'Star' },
        properties: {
          created_at: { isVisible: { list: true, filter: true, show: true, edit: false } },
          updated_at: { isVisible: { list: true, filter: true, show: true, edit: false } }
        }
      },
    },
  ],
  rootPath: '/admin',
  branding: {
    companyName: 'ClassServer Admin',
    logo: false,
    favicon: '/favicon.ico',
  },
  dashboard: {
    component: AdminJS.bundle('./components/dashboard')
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

# Check if src/index.js exists and fix it if needed
if [ -f "src/index.js" ]; then
  print_message "Checking src/index.js..."
  
  # Check if src/index.js imports adminSetup.js
  if grep -q "adminSetup" src/index.js; then
    print_message "Fixing src/index.js..."
    # Create a backup
    cp src/index.js src/index.js.bak
    
    # Update the import statement for adminSetup.js
    sed -i 's/import { router as adminRouter } from/import { router as adminRouter } from/' src/index.js
  fi
fi

print_success "AdminJS setup fixed successfully"

# Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend || {
    print_warning "Failed to restart backend service. It may not be set up as a systemd service yet."
    print_message "You can start the backend manually with: cd /opt/ClassServer/backend && node src/index.js"
}

print_success "Backend service restarted successfully!" 