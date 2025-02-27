#!/bin/bash

# Script to fix the Match model and AdminJS permissions issue
# This script updates the model files to match the database schema and fixes permissions

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting Match model fix script...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Create .adminjs directory with proper permissions
echo -e "${YELLOW}Creating .adminjs directory with proper permissions...${NC}"
mkdir -p /opt/ClassServer/backend/.adminjs
chown -R classserver:classserver /opt/ClassServer/backend/.adminjs
chmod -R 755 /opt/ClassServer/backend/.adminjs

# Update the Match model file
echo -e "${YELLOW}Updating Match model file...${NC}"
cat > /opt/ClassServer/backend/src/models/match.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  const Match = sequelize.define('Match', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    game_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'games',
        key: 'id'
      }
    },
    player1_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    player2_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    player1_score: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    },
    player2_score: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    },
    winner_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    played_at: {
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
    tableName: 'matches',
    timestamps: true,
    underscored: true
  });

  return Match;
};
EOF

# Update the models/index.js file
echo -e "${YELLOW}Updating models/index.js file...${NC}"
cat > /opt/ClassServer/backend/src/models/index.js << 'EOF'
import { Sequelize } from 'sequelize';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { readdirSync } from 'fs';

// Get the directory name of the current module
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Database configuration
const config = {
  username: process.env.DB_USERNAME || 'classserver',
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
    logging: config.logging,
    define: {
      underscored: true,
      timestamps: true,
      createdAt: 'created_at',
      updatedAt: 'updated_at'
    }
  }
);

// Import all models dynamically
const importModels = async () => {
  const models = {};
  
  // Read all files in the models directory
  const files = readdirSync(__dirname)
    .filter(file => file !== 'index.js' && file.endsWith('.js'));
  
  // Import each model file
  for (const file of files) {
    const modelPath = join(__dirname, file);
    const modelModule = await import(modelPath);
    const model = modelModule.default(sequelize);
    models[model.name] = model;
  }
  
  return models;
};

// Initialize models and associations
const initializeModels = async () => {
  const models = await importModels();
  
  // Define associations
  if (models.User && models.Match) {
    models.User.hasMany(models.Match, { foreignKey: 'player1_id', as: 'matchesAsPlayer1' });
    models.User.hasMany(models.Match, { foreignKey: 'player2_id', as: 'matchesAsPlayer2' });
    models.User.hasMany(models.Match, { foreignKey: 'winner_id', as: 'wonMatches' });
    models.Match.belongsTo(models.User, { foreignKey: 'player1_id', as: 'player1' });
    models.Match.belongsTo(models.User, { foreignKey: 'player2_id', as: 'player2' });
    models.Match.belongsTo(models.User, { foreignKey: 'winner_id', as: 'winner' });
  }
  
  if (models.Game && models.Match) {
    models.Game.hasMany(models.Match, { foreignKey: 'game_id' });
    models.Match.belongsTo(models.Game, { foreignKey: 'game_id' });
  }
  
  if (models.User && models.UserElo && models.Game) {
    models.User.hasMany(models.UserElo, { foreignKey: 'user_id' });
    models.Game.hasMany(models.UserElo, { foreignKey: 'game_id' });
    models.UserElo.belongsTo(models.User, { foreignKey: 'user_id' });
    models.UserElo.belongsTo(models.Game, { foreignKey: 'game_id' });
  }
  
  return models;
};

// Initialize models
const db = { sequelize, Sequelize };

// Export the database object
export default db;

// Initialize models when this module is imported
(async () => {
  try {
    const models = await initializeModels();
    Object.assign(db, models);
    console.log('Models initialized successfully');
  } catch (error) {
    console.error('Failed to initialize models:', error);
  }
})();
EOF

# Update the adminSetup.js file
echo -e "${YELLOW}Updating adminSetup.js file...${NC}"
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

# Set proper permissions for all files
echo -e "${YELLOW}Setting proper permissions for all files...${NC}"
chown -R classserver:classserver /opt/ClassServer/backend/src/models/match.js
chown -R classserver:classserver /opt/ClassServer/backend/src/models/index.js
chown -R classserver:classserver /opt/ClassServer/backend/adminSetup.js

# Restart the backend service
echo -e "${YELLOW}Restarting the backend service...${NC}"
systemctl restart classserver-backend

echo -e "${GREEN}Match model fix completed successfully!${NC}"
echo -e "${GREEN}You can now access the admin panel at http://localhost:8000/admin${NC}"
echo -e "${GREEN}Login with: admin@classserver.com / classserver${NC}"

exit 0 