#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Setting up AdminJS for ClassServer..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Step 1: Install AdminJS and required packages
print_message "Installing AdminJS and required packages..."
npm install adminjs @adminjs/express @adminjs/sequelize express-formidable express-session

# Step 2: Update package.json to support ES Modules
print_message "Updating package.json to support ES Modules..."
cat > package.json << 'EOF'
{
  "name": "@classserver/backend",
  "version": "1.0.0",
  "description": "ClassServer Backend API",
  "type": "module",
  "main": "src/index.js",
  "scripts": {
    "start": "nodemon src/index.js",
    "build": "echo \"No build step required\" && exit 0",
    "test": "echo \"Error: no test specified\" && exit 1",
    "lint": "eslint .",
    "migrate": "sequelize-cli db:migrate",
    "seed": "sequelize-cli db:seed:all"
  },
  "dependencies": {
    "@adminjs/express": "^6.0.0",
    "@adminjs/sequelize": "^4.0.0",
    "adminjs": "^7.0.0",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3",
    "express": "^4.18.2",
    "express-formidable": "^1.2.0",
    "express-session": "^1.17.3",
    "morgan": "^1.10.0",
    "pg": "^8.10.0",
    "pg-hstore": "^2.3.4",
    "sequelize": "^6.31.0"
  },
  "devDependencies": {
    "eslint": "^8.38.0",
    "nodemon": "^3.0.1",
    "sequelize-cli": "^6.6.0"
  }
}
EOF

# Step 3: Convert model files to ES Modules
print_message "Converting model files to ES Modules..."

# Fix game.js
print_message "Updating src/models/game.js..."
cat > src/models/game.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  const Game = sequelize.define('Game', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false
    },
    description: {
      type: DataTypes.TEXT,
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
    tableName: 'games',
    timestamps: true,
    underscored: true
  });

  return Game;
};
EOF

# Fix match.js
print_message "Updating src/models/match.js..."
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
    winner_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    loser_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    winner_score: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    loser_score: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    played_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
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

# Fix user.js
print_message "Updating src/models/user.js..."
cat > src/models/user.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  const User = sequelize.define('User', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    username: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true
    },
    rfid_uid: {
      type: DataTypes.STRING,
      allowNull: true,
      unique: true
    },
    email: {
      type: DataTypes.STRING,
      allowNull: true,
      unique: true,
      validate: {
        isEmail: true
      }
    },
    active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
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
    tableName: 'users',
    timestamps: true,
    underscored: true
  });

  return User;
};
EOF

# Fix userElo.js
print_message "Updating src/models/userElo.js..."
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
    elo: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 1000
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

# Fix index.js
print_message "Updating src/models/index.js..."
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
    models.User.hasMany(models.Match, { foreignKey: 'winner_id', as: 'wonMatches' });
    models.User.hasMany(models.Match, { foreignKey: 'loser_id', as: 'lostMatches' });
    models.Match.belongsTo(models.User, { foreignKey: 'winner_id', as: 'winner' });
    models.Match.belongsTo(models.User, { foreignKey: 'loser_id', as: 'loser' });
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

# Step 4: Fix route files
print_message "Updating route files..."

# Fix auth.js
print_message "Updating routes/auth.js..."
cat > routes/auth.js << 'EOF'
import express from 'express';
import db from '../src/models/index.js';

const router = express.Router();
const { User } = db;

/**
 * @route GET /auth/users
 * @desc Get all users
 * @access Public
 */
router.get('/users', async (req, res) => {
  try {
    const users = await User.findAll({
      attributes: ['id', 'username', 'email', 'rfid_uid', 'active']
    });
    
    res.json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

export default router;
EOF

# Fix games.js
print_message "Updating routes/games.js..."
cat > routes/games.js << 'EOF'
import express from 'express';
import db from '../src/models/index.js';

const router = express.Router();
const { Game, Match, User, UserElo } = db;

/**
 * @route GET /games
 * @desc Get all games
 * @access Public
 */
router.get('/', async (req, res) => {
  try {
    const games = await Game.findAll();
    res.json(games);
  } catch (error) {
    console.error('Error fetching games:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

/**
 * @route GET /games/:id
 * @desc Get game by ID
 * @access Public
 */
router.get('/:id', async (req, res) => {
  try {
    const game = await Game.findByPk(req.params.id);
    if (!game) {
      return res.status(404).json({ message: 'Game not found' });
    }
    res.json(game);
  } catch (error) {
    console.error('Error fetching game:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

/**
 * @route GET /games/:id/matches
 * @desc Get matches for a game
 * @access Public
 */
router.get('/:id/matches', async (req, res) => {
  try {
    const matches = await Match.findAll({
      where: { game_id: req.params.id },
      include: [
        { model: User, as: 'winner' },
        { model: User, as: 'loser' },
        { model: Game }
      ]
    });
    res.json(matches);
  } catch (error) {
    console.error('Error fetching matches:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

/**
 * @route GET /games/:id/rankings
 * @desc Get rankings for a game
 * @access Public
 */
router.get('/:id/rankings', async (req, res) => {
  try {
    const rankings = await UserElo.findAll({
      where: { game_id: req.params.id },
      include: [{ model: User }],
      order: [['elo', 'DESC']]
    });
    res.json(rankings);
  } catch (error) {
    console.error('Error fetching rankings:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

export default router;
EOF

# Step 5: Create AdminJS setup
print_message "Creating AdminJS setup..."
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

# Step 6: Update src/index.js
print_message "Updating src/index.js..."
cat > src/index.js << 'EOF'
import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import db from './models/index.js';
import { router as adminRouter } from '../adminSetup.js';

// Import routes
import authRoutes from '../routes/auth.js';
import gamesRoutes from '../routes/games.js';

const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Mount the admin panel
app.use('/admin', adminRouter);

// Routes
app.use('/auth', authRoutes);
app.use('/games', gamesRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({ 
    message: 'Welcome to ClassServer API',
    adminPanel: `${req.protocol}://${req.get('host')}/admin`
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Start server
async function startServer() {
  try {
    // Test database connection
    await db.sequelize.authenticate();
    console.log('Database connection established successfully');
    
    // Start server
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`Admin panel available at: http://localhost:${PORT}/admin`);
    });
  } catch (error) {
    console.error('Unable to connect to the database:', error);
  }
}

// Call the function to start the server
startServer();
EOF

# Step 7: Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend || {
    print_warning "Failed to restart backend service. It may not be set up as a systemd service yet."
    print_message "You can start the backend manually with: cd /opt/ClassServer/backend && node src/index.js"
}

print_success "AdminJS setup completed successfully!"
print_message "You can access the admin panel at: http://localhost:8000/admin"
print_message "Login with:"
print_message "  Email: admin@classserver.com"
print_message "  Password: classserver" 