#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Fixing AdminJS configuration for async model loading..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Update adminSetup.js to handle async model loading
print_message "Updating adminSetup.js to handle async model loading..."
cat > adminSetup.js << 'EOF'
import AdminJS from 'adminjs';
import AdminJSExpress from '@adminjs/express';
import AdminJSSequelize from '@adminjs/sequelize';
import session from 'express-session';
import db from './src/models/index.js';

// Register Sequelize adapter
AdminJS.registerAdapter(AdminJSSequelize);

// Create admin credentials - in production, use environment variables
const DEFAULT_ADMIN = {
  email: 'admin@classserver.com',
  password: 'classserver',
};

// Function to initialize AdminJS with models
const initializeAdmin = async () => {
  // Wait for models to be loaded
  await new Promise(resolve => {
    const checkModels = () => {
      if (db.User && db.Game && db.Match && db.UserElo) {
        resolve();
      } else {
        setTimeout(checkModels, 100);
      }
    };
    checkModels();
  });

  // Define AdminJS instance with models
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

  return { adminJs, router };
};

export { initializeAdmin };
EOF

# Update src/index.js to use the async AdminJS initialization
print_message "Updating src/index.js to use async AdminJS initialization..."
cat > src/index.js << 'EOF'
import express from 'express';
import cors from 'cors';
import { initializeAdmin } from '../adminSetup.js';
import authRoutes from './routes/auth.js';
import gameRoutes from './routes/games.js';

const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/games', gameRoutes);

// Health check route
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Initialize AdminJS asynchronously
const startServer = async () => {
  try {
    // Initialize AdminJS
    const { router: adminRouter } = await initializeAdmin();
    
    // Mount AdminJS router
    app.use('/admin', adminRouter);
    
    // Start server
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Start the server
startServer();
EOF

print_success "AdminJS configuration fixed successfully"

# Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend || {
    print_warning "Failed to restart backend service. It may not be set up as a systemd service yet."
    print_message "You can start the backend manually with: cd /opt/ClassServer/backend && node src/index.js"
}

print_success "Backend service restarted successfully!"
print_message "You can now use the admin panel at: http://localhost:8000/admin"
print_message "Login with:"
print_message "  Email: admin@classserver.com"
print_message "  Password: classserver" 