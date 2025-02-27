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
      order: [['elo', 'DESC']]
    });
    
    return res.status(200).json(leaderboard);
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    return res.status(500).json({ message: 'Server error' });
  }
});

export default router;
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
      { game_id: 1, winner_id: 1, loser_id: 2, winner_score: 3, loser_score: 2, played_at: now },
      { game_id: 1, winner_id: 3, loser_id: 4, winner_score: 2, loser_score: 0, played_at: yesterday },
      { game_id: 2, winner_id: 2, loser_id: 3, winner_score: 21, loser_score: 15, played_at: twoDaysAgo },
      { game_id: 2, winner_id: 1, loser_id: 4, winner_score: 21, loser_score: 18, played_at: threeDaysAgo },
      { game_id: 3, winner_id: 4, loser_id: 1, winner_score: 10, loser_score: 8, played_at: yesterday },
      { game_id: 3, winner_id: 3, loser_id: 2, winner_score: 10, loser_score: 5, played_at: now },
      { game_id: 4, winner_id: 2, loser_id: 1, winner_score: 301, loser_score: 275, played_at: twoDaysAgo },
      { game_id: 4, winner_id: 4, loser_id: 3, winner_score: 301, loser_score: 268, played_at: threeDaysAgo }
    ]);
    
    console.log('Adding sample ELO ratings...');
    await db.UserElo.bulkCreate([
      { user_id: 1, game_id: 1, elo: 1520 },
      { user_id: 2, game_id: 1, elo: 1480 },
      { user_id: 3, game_id: 1, elo: 1550 },
      { user_id: 4, game_id: 1, elo: 1450 },
      { user_id: 1, game_id: 2, elo: 1510 },
      { user_id: 2, game_id: 2, elo: 1540 },
      { user_id: 3, game_id: 2, elo: 1470 },
      { user_id: 4, game_id: 2, elo: 1480 },
      { user_id: 1, game_id: 3, elo: 1490 },
      { user_id: 2, game_id: 3, elo: 1480 },
      { user_id: 3, game_id: 3, elo: 1530 },
      { user_id: 4, game_id: 3, elo: 1500 },
      { user_id: 1, game_id: 4, elo: 1490 },
      { user_id: 2, game_id: 4, elo: 1520 },
      { user_id: 3, game_id: 4, elo: 1480 },
      { user_id: 4, game_id: 4, elo: 1510 }
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

print_success "AdminJS admin panel setup completed successfully!"
print_message "You can now use the admin panel at: http://localhost:8000/admin"
print_message "Login with:"
print_message "  Email: admin@classserver.com"
print_message "  Password: classserver"
print_message ""
print_message "The admin panel includes:"
print_message "  - User Management: Add, edit, and delete users"
print_message "  - Game Management: Manage game types"
print_message "  - Match History: View and edit match records"
print_message "  - ELO Ratings: Manage player ratings" 