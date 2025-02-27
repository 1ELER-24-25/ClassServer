#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Setting up AdminJS admin panel..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Install required packages
print_message "Installing AdminJS and required packages..."
npm install adminjs @adminjs/express @adminjs/sequelize express-formidable express-session

# Update package.json to support ES Modules
print_message "Updating package.json to support ES Modules..."
if ! grep -q '"type": "module"' package.json; then
  # Create a backup of the original package.json
  cp package.json package.json.bak
  
  # Add "type": "module" to package.json
  sed -i '/"name": "@classserver\/backend"/a \  "type": "module",' package.json
  
  print_success "package.json updated to support ES Modules"
else
  print_message "package.json already supports ES Modules"
fi

# Create .adminjs directory with proper permissions
print_message "Creating .adminjs directory with proper permissions..."
mkdir -p .adminjs
chmod -R 755 .adminjs

# Create routes directory if it doesn't exist
mkdir -p src/routes

# Create auth.js route file
print_message "Creating auth.js route file..."
cat > src/routes/auth.js << 'EOF'
import express from 'express';
import db from '../models/index.js';

const router = express.Router();

// Login route
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    // Simple authentication for now
    // In production, use proper password hashing
    const user = await db.User.findOne({
      where: { username, active: true }
    });
    
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    // In a real app, you would verify the password hash here
    
    return res.status(200).json({
      id: user.id,
      username: user.username,
      email: user.email
    });
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Get current user
router.get('/me', async (req, res) => {
  // In a real app, you would verify the JWT token here
  // For now, just return a placeholder response
  return res.status(200).json({ message: 'Authentication required' });
});

export default router;
EOF

# Create games.js route file
print_message "Creating games.js route file..."
cat > src/routes/games.js << 'EOF'
import express from 'express';
import db from '../models/index.js';

const router = express.Router();

// Get all games
router.get('/', async (req, res) => {
  try {
    const games = await db.Game.findAll();
    return res.status(200).json(games);
  } catch (error) {
    console.error('Error fetching games:', error);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Get a specific game
router.get('/:id', async (req, res) => {
  try {
    const game = await db.Game.findByPk(req.params.id);
    
    if (!game) {
      return res.status(404).json({ message: 'Game not found' });
    }
    
    return res.status(200).json(game);
  } catch (error) {
    console.error('Error fetching game:', error);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Get matches for a specific game
router.get('/:id/matches', async (req, res) => {
  try {
    const matches = await db.Match.findAll({
      where: { game_id: req.params.id },
      order: [['played_at', 'DESC']]
    });
    
    return res.status(200).json(matches);
  } catch (error) {
    console.error('Error fetching matches:', error);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Get leaderboard for a specific game
router.get('/:id/leaderboard', async (req, res) => {
  try {
    const leaderboard = await db.UserElo.findAll({
      where: { game_id: req.params.id },
      include: [
        {
          model: db.User,
          attributes: ['id', 'username', 'email']
        }
      ],
      order: [['rating', 'DESC']]
    });
    
    return res.status(200).json(leaderboard);
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    return res.status(500).json({ message: 'Server error' });
  }
});

export default router;
EOF

# Update the Match model file to match database schema
print_message "Updating Match model file to match database schema..."
cat > src/models/match.js << 'EOF'
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

# Update the UserElo model file to match database schema
print_message "Updating UserElo model file to match database schema..."
cat > src/models/userElo.js << 'EOF'
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

# Update the models/index.js file to use correct associations
print_message "Updating models/index.js file with correct associations..."
cat > src/models/index.js << 'EOF'
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

# Create AdminJS configuration file
print_message "Creating AdminJS configuration file..."
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

# Update src/index.js to use AdminJS
print_message "Updating src/index.js to use AdminJS..."
cat > src/index.js << 'EOF'
import express from 'express';
import cors from 'cors';
import { initializeAdmin } from '../adminSetup.js';

const app = express();
const PORT = process.env.PORT || 8000;

// Only apply CORS middleware before AdminJS
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
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Start the server
startServer();
EOF

# Create a temporary JavaScript file to add sample data
print_message "Creating script to add sample data..."
cat > add_sample_data.js << 'EOF'
import db from './src/models/index.js';

// Wait for models to be initialized
const waitForModels = async () => {
  return new Promise(resolve => {
    const checkModels = () => {
      if (db.User && db.Game && db.Match && db.UserElo) {
        resolve();
      } else {
        setTimeout(checkModels, 100);
      }
    };
    checkModels();
  });
};

// Add sample data
const addSampleData = async () => {
  try {
    await waitForModels();
    
    // Check if data already exists
    const userCount = await db.User.count();
    if (userCount > 0) {
      console.log('Sample data already exists, skipping...');
      process.exit(0);
      return;
    }
    
    console.log('Adding sample users...');
    const users = await db.User.bulkCreate([
      { username: 'john_doe', email: 'john@example.com', rfid_uid: '12345678', active: true },
      { username: 'jane_smith', email: 'jane@example.com', rfid_uid: '87654321', active: true },
      { username: 'bob_johnson', email: 'bob@example.com', rfid_uid: '23456789', active: true },
      { username: 'alice_williams', email: 'alice@example.com', rfid_uid: '98765432', active: true }
    ]);
    
    console.log('Adding sample games...');
    const games = await db.Game.bulkCreate([
      { name: 'Chess', description: 'Classic strategy board game' },
      { name: 'Ping Pong', description: 'Table tennis game' },
      { name: 'Foosball', description: 'Table football game' },
      { name: 'Darts', description: 'Throwing darts at a circular target' }
    ]);
    
    console.log('Adding sample matches...');
    const now = new Date();
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    const twoDaysAgo = new Date(now);
    twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);
    const threeDaysAgo = new Date(now);
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
    
    await db.Match.bulkCreate([
      { game_id: 1, player1_id: 1, player2_id: 2, player1_score: 3, player2_score: 2, winner_id: 1, played_at: now },
      { game_id: 1, player1_id: 3, player2_id: 4, player1_score: 2, player2_score: 0, winner_id: 3, played_at: yesterday },
      { game_id: 2, player1_id: 2, player2_id: 3, player1_score: 21, player2_score: 15, winner_id: 2, played_at: twoDaysAgo },
      { game_id: 2, player1_id: 1, player2_id: 4, player1_score: 21, player2_score: 18, winner_id: 1, played_at: threeDaysAgo },
      { game_id: 3, player1_id: 4, player2_id: 1, player1_score: 10, player2_score: 8, winner_id: 4, played_at: yesterday },
      { game_id: 3, player1_id: 3, player2_id: 2, player1_score: 10, player2_score: 5, winner_id: 3, played_at: now }
    ]);
    
    console.log('Adding sample ELO ratings...');
    await db.UserElo.bulkCreate([
      { user_id: 1, game_id: 1, rating: 1520, wins: 5, losses: 2, last_played: now },
      { user_id: 2, game_id: 1, rating: 1480, wins: 3, losses: 4, last_played: yesterday },
      { user_id: 3, game_id: 1, rating: 1550, wins: 7, losses: 1, last_played: twoDaysAgo },
      { user_id: 4, game_id: 1, rating: 1450, wins: 2, losses: 5, last_played: threeDaysAgo },
      { user_id: 1, game_id: 2, rating: 1510, wins: 4, losses: 3, last_played: now },
      { user_id: 2, game_id: 2, rating: 1540, wins: 6, losses: 2, last_played: yesterday },
      { user_id: 3, game_id: 2, rating: 1470, wins: 3, losses: 4, last_played: twoDaysAgo },
      { user_id: 4, game_id: 2, rating: 1480, wins: 3, losses: 3, last_played: threeDaysAgo }
    ]);
    
    console.log('Sample data added successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error adding sample data:', error);
    process.exit(1);
  }
};

// Run the function
addSampleData();
EOF

# Run the script to add sample data
print_message "Adding sample data to the database..."
node add_sample_data.js || {
  print_warning "Failed to add sample data. This may be because data already exists."
}

# Clean up
print_message "Cleaning up..."
rm -f add_sample_data.js

# Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend || {
    print_warning "Failed to restart backend service. It may not be set up as a systemd service yet."
    print_message "You can start the backend manually with: cd /opt/ClassServer/backend && node src/index.js"
}

# Get server IP address for display
SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="your-server-ip"
fi

print_success "AdminJS admin panel setup completed successfully!"
print_message "You can now use the admin panel at: http://localhost:8000/admin"
print_message "Or from other machines on the network at: http://${SERVER_IP}:8000/admin"
print_message "Login with:"
print_message "  Email: admin@classserver.com"
print_message "  Password: classserver"
print_message ""
print_message "The admin panel includes:"
print_message "  - User Management: Add, edit, and delete users"
print_message "  - Game Management: Manage game types"
print_message "  - Match History: View and edit match records"
print_message "  - ELO Ratings: Manage player ratings" 