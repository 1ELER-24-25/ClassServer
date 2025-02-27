#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Enhancing AdminJS panel with more features..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Update adminSetup.js to include more features and better resource configuration
print_message "Updating adminSetup.js with enhanced features..."
cat > adminSetup.js << 'EOF'
import AdminJS from 'adminjs';
import AdminJSExpress from '@adminjs/express';
import AdminJSSequelize from '@adminjs/sequelize';
import session from 'express-session';
import db from './src/models/index.js';

// Register Sequelize adapter
AdminJS.registerAdapter(AdminJSSequelize);

// Define AdminJS instance with enhanced configuration
const adminJs = new AdminJS({
  databases: [db.sequelize],
  rootPath: '/admin',
  branding: {
    companyName: 'ClassServer Admin',
    logo: false,
    favicon: '/favicon.ico',
  },
  resources: [
    {
      resource: db.User,
      options: {
        navigation: { name: 'User Management', icon: 'User' },
        listProperties: ['id', 'username', 'email', 'rfid_uid', 'active', 'created_at'],
        editProperties: ['username', 'email', 'rfid_uid', 'active'],
        filterProperties: ['username', 'email', 'active', 'created_at'],
        properties: {
          id: { isTitle: true },
          created_at: { isVisible: { list: true, filter: true, show: true, edit: false } },
          updated_at: { isVisible: { list: false, filter: true, show: true, edit: false } }
        },
        actions: {
          new: {
            isAccessible: true,
            before: async (request) => {
              // Set default values for new users
              request.payload = {
                ...request.payload,
                active: true
              };
              return request;
            }
          }
        }
      }
    },
    {
      resource: db.Game,
      options: {
        navigation: { name: 'Game Management', icon: 'Game' },
        listProperties: ['id', 'name', 'description', 'created_at'],
        editProperties: ['name', 'description'],
        filterProperties: ['name', 'created_at'],
        properties: {
          id: { isTitle: true },
          name: { isTitle: true },
          created_at: { isVisible: { list: true, filter: true, show: true, edit: false } },
          updated_at: { isVisible: { list: false, filter: true, show: true, edit: false } }
        }
      }
    },
    {
      resource: db.Match,
      options: {
        navigation: { name: 'Match History', icon: 'Activity' },
        listProperties: ['id', 'game_id', 'winner_id', 'loser_id', 'winner_score', 'loser_score', 'played_at'],
        editProperties: ['game_id', 'winner_id', 'loser_id', 'winner_score', 'loser_score', 'played_at'],
        filterProperties: ['game_id', 'winner_id', 'loser_id', 'played_at'],
        properties: {
          id: { isTitle: true },
          played_at: { 
            isVisible: { list: true, filter: true, show: true, edit: true },
            type: 'datetime'
          },
          created_at: { isVisible: { list: false, filter: true, show: true, edit: false } },
          updated_at: { isVisible: { list: false, filter: true, show: true, edit: false } }
        }
      }
    },
    {
      resource: db.UserElo,
      options: {
        navigation: { name: 'ELO Ratings', icon: 'Star' },
        listProperties: ['id', 'user_id', 'game_id', 'elo', 'created_at'],
        editProperties: ['user_id', 'game_id', 'elo'],
        filterProperties: ['user_id', 'game_id', 'elo'],
        properties: {
          id: { isTitle: true },
          created_at: { isVisible: { list: true, filter: true, show: true, edit: false } },
          updated_at: { isVisible: { list: false, filter: true, show: true, edit: false } }
        }
      }
    }
  ]
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

print_success "AdminJS panel enhanced successfully"

# Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend || {
    print_warning "Failed to restart backend service. It may not be set up as a systemd service yet."
    print_message "You can start the backend manually with: cd /opt/ClassServer/backend && node src/index.js"
}

print_success "Backend service restarted successfully!"
print_message "You can now use the enhanced admin panel at: http://localhost:8000/admin"
print_message "Login with:"
print_message "  Email: admin@classserver.com"
print_message "  Password: classserver"
print_message ""
print_message "The admin panel now includes:"
print_message "  - User Management: Add, edit, and delete users"
print_message "  - Game Management: Manage game types"
print_message "  - Match History: View and edit match records"
print_message "  - ELO Ratings: Manage player ratings" 