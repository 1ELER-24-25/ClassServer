#!/bin/bash

# Script to fix the UserElo model to match the database schema
# This script updates the UserElo model file

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting UserElo model fix script...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Update the UserElo model file
echo -e "${YELLOW}Updating UserElo model file...${NC}"
cat > /opt/ClassServer/backend/src/models/userElo.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  const UserElo = sequelize.define('UserElo', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    game_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'games',
        key: 'id'
      }
    },
    rating: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 1200
    },
    wins: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    },
    losses: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    },
    last_played: {
      type: DataTypes.DATE,
      allowNull: true
    },
    created_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    },
    updated_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    tableName: 'user_elos',
    timestamps: true,
    underscored: true
  });

  return UserElo;
};
EOF

# Update the adminSetup.js file to reflect the new field names
echo -e "${YELLOW}Updating adminSetup.js file for UserElo...${NC}"
cat > /opt/ClassServer/backend/adminSetup.js << 'EOF'
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
          listProperties: ['id', 'game_id', 'player1_id', 'player2_id', 'player1_score', 'player2_score', 'winner_id', 'played_at'],
          editProperties: ['game_id', 'player1_id', 'player2_id', 'player1_score', 'player2_score', 'winner_id', 'played_at'],
          filterProperties: ['game_id', 'player1_id', 'player2_id', 'winner_id', 'played_at'],
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
          listProperties: ['id', 'user_id', 'game_id', 'rating', 'wins', 'losses', 'last_played', 'created_at'],
          editProperties: ['user_id', 'game_id', 'rating', 'wins', 'losses', 'last_played'],
          filterProperties: ['user_id', 'game_id', 'rating', 'wins', 'losses'],
          properties: {
            id: { isTitle: true },
            rating: { isTitle: true },
            last_played: {
              isVisible: { list: true, filter: true, show: true, edit: true },
              type: 'datetime'
            },
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

# Restart the backend service
echo -e "${YELLOW}Restarting the backend service...${NC}"
systemctl restart classserver-backend

echo -e "${GREEN}UserElo model fix completed successfully!${NC}"
echo -e "${GREEN}You can now access the admin panel at http://localhost:8000/admin${NC}"
echo -e "${GREEN}Login with: admin@classserver.com / classserver${NC}"

exit 0