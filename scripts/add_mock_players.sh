#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Adding mock players to the database..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Create necessary directories
mkdir -p src/scripts
mkdir -p src/config
mkdir -p src/models
mkdir -p routes

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    print_error "PostgreSQL is not installed. Please install it first."
    exit 1
fi

# Set database credentials
DB_NAME="classserver"
DB_USER="classserver"
DB_PASSWORD=${DB_PASSWORD:-"classserver"}

# Check if PostgreSQL user exists and create if needed
print_message "Checking PostgreSQL user..."
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    print_message "Creating PostgreSQL user '$DB_USER'..."
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
fi

# Check if database exists and create if needed
print_message "Checking PostgreSQL database..."
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
    print_message "Creating PostgreSQL database '$DB_NAME'..."
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
fi

# Grant privileges
print_message "Granting privileges..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# Export password for Sequelize to use
export DB_PASSWORD="$DB_PASSWORD"

# Create database configuration file
print_message "Creating database configuration..."
cat > src/config/database.js << 'EOF'
module.exports = {
  database: process.env.DB_NAME || 'classserver',
  username: process.env.DB_USER || 'classserver',
  password: process.env.DB_PASSWORD || 'classserver',
  host: process.env.DB_HOST || 'localhost',
  dialect: 'postgres',
  logging: false
};
EOF

# Create model files
print_message "Creating database models..."

# Create User model if it doesn't exist
if [ ! -f "src/models/user.js" ]; then
    print_message "Creating User model..."
    cat > src/models/user.js << 'EOF'
const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
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
    email: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        isEmail: true
      }
    },
    rfid_uid: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true
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
fi

# Create Game model
print_message "Creating Game model..."
cat > src/models/game.js << 'EOF'
const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Game = sequelize.define('Game', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true
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
    tableName: 'games',
    timestamps: true,
    underscored: true
  });

  return Game;
};
EOF

# Create Match model
print_message "Creating Match model..."
cat > src/models/match.js << 'EOF'
const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Match = sequelize.define('Match', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
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
    game_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'games',
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

# Create UserElo model
print_message "Creating UserElo model..."
cat > src/models/userElo.js << 'EOF'
const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
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
      defaultValue: 1200 // Default ELO rating
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
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ['user_id', 'game_id']
      }
    ]
  });

  return UserElo;
};
EOF

# Create models index file
print_message "Creating models index file..."
cat > src/models/index.js << 'EOF'
const { Sequelize } = require('sequelize');
const config = require('../config/database');

const sequelize = new Sequelize(config.database, config.username, config.password, {
  host: config.host,
  dialect: config.dialect,
  logging: false
});

// Import models
const User = require('./user')(sequelize);
const Game = require('./game')(sequelize);
const Match = require('./match')(sequelize);
const UserElo = require('./userElo')(sequelize);

// Define associations
User.hasMany(Match, { foreignKey: 'player1_id' });
User.hasMany(Match, { foreignKey: 'player2_id' });
User.hasMany(UserElo, { foreignKey: 'user_id' });

Game.hasMany(Match, { foreignKey: 'game_id' });
Game.hasMany(UserElo, { foreignKey: 'game_id' });

Match.belongsTo(User, { as: 'player1', foreignKey: 'player1_id' });
Match.belongsTo(User, { as: 'player2', foreignKey: 'player2_id' });
Match.belongsTo(Game, { foreignKey: 'game_id' });

UserElo.belongsTo(User, { foreignKey: 'user_id' });
UserElo.belongsTo(Game, { foreignKey: 'game_id' });

module.exports = {
  sequelize,
  User,
  Game,
  Match,
  UserElo
};
EOF

# Check if the mock data script exists
if [ ! -f "src/scripts/add_mock_data.js" ]; then
    print_message "Creating mock data script..."
    
    # Create the script
    cat > src/scripts/add_mock_data.js << 'EOF'
/**
 * Script to add mock data to the database for testing purposes
 * Run with: node src/scripts/add_mock_data.js
 */

const { sequelize, User, Game, Match, UserElo } = require('../models');

async function addMockData() {
  try {
    console.log('Starting to add mock data...');
    
    // Sync database models
    await sequelize.sync({ alter: true });
    console.log('Database synced');
    
    // Add game types
    const games = await Game.bulkCreate([
      { name: 'foosball', description: 'Table football game' },
      { name: 'chess', description: 'Classic chess game' }
    ], { ignoreDuplicates: true });
    console.log('Game types added');
    
    // Get game IDs
    const foosballId = (await Game.findOne({ where: { name: 'foosball' } })).id;
    const chessId = (await Game.findOne({ where: { name: 'chess' } })).id;
    
    // Add mock users
    const users = await User.bulkCreate([
      { username: 'Player1', email: 'player1@example.com', rfid_uid: 'RFID001' },
      { username: 'Player2', email: 'player2@example.com', rfid_uid: 'RFID002' },
      { username: 'Player3', email: 'player3@example.com', rfid_uid: 'RFID003' },
      { username: 'Player4', email: 'player4@example.com', rfid_uid: 'RFID004' },
      { username: 'Player5', email: 'player5@example.com', rfid_uid: 'RFID005' }
    ], { ignoreDuplicates: true });
    console.log('Mock users added');
    
    // Get user IDs
    const userIds = {};
    for (let i = 1; i <= 5; i++) {
      const user = await User.findOne({ where: { username: `Player${i}` } });
      userIds[`player${i}`] = user.id;
    }
    
    // Add user ELO ratings for foosball
    await UserElo.bulkCreate([
      { user_id: userIds.player1, game_id: foosballId, rating: 1450, wins: 15, losses: 5 },
      { user_id: userIds.player2, game_id: foosballId, rating: 1380, wins: 12, losses: 8 },
      { user_id: userIds.player3, game_id: foosballId, rating: 1320, wins: 10, losses: 10 },
      { user_id: userIds.player4, game_id: foosballId, rating: 1280, wins: 8, losses: 12 },
      { user_id: userIds.player5, game_id: foosballId, rating: 1220, wins: 6, losses: 14 }
    ], { updateOnDuplicate: ['rating', 'wins', 'losses'] });
    console.log('Foosball ELO ratings added');
    
    // Add user ELO ratings for chess
    await UserElo.bulkCreate([
      { user_id: userIds.player3, game_id: chessId, rating: 1520, wins: 18, losses: 2 },
      { user_id: userIds.player1, game_id: chessId, rating: 1480, wins: 16, losses: 4 },
      { user_id: userIds.player5, game_id: chessId, rating: 1350, wins: 11, losses: 9 },
      { user_id: userIds.player2, game_id: chessId, rating: 1300, wins: 9, losses: 11 },
      { user_id: userIds.player4, game_id: chessId, rating: 1250, wins: 7, losses: 13 }
    ], { updateOnDuplicate: ['rating', 'wins', 'losses'] });
    console.log('Chess ELO ratings added');
    
    // Add some mock matches
    const twoWeeksAgo = new Date();
    twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);
    
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    
    await Match.bulkCreate([
      // Foosball matches
      { 
        player1_id: userIds.player1, 
        player2_id: userIds.player2, 
        game_id: foosballId, 
        player1_score: 10, 
        player2_score: 8, 
        winner_id: userIds.player1,
        played_at: twoWeeksAgo
      },
      { 
        player1_id: userIds.player3, 
        player2_id: userIds.player4, 
        game_id: foosballId, 
        player1_score: 10, 
        player2_score: 5, 
        winner_id: userIds.player3,
        played_at: oneWeekAgo
      },
      { 
        player1_id: userIds.player1, 
        player2_id: userIds.player5, 
        game_id: foosballId, 
        player1_score: 10, 
        player2_score: 7, 
        winner_id: userIds.player1,
        played_at: yesterday
      },
      
      // Chess matches
      { 
        player1_id: userIds.player3, 
        player2_id: userIds.player1, 
        game_id: chessId, 
        player1_score: 1, 
        player2_score: 0, 
        winner_id: userIds.player3,
        played_at: twoWeeksAgo
      },
      { 
        player1_id: userIds.player5, 
        player2_id: userIds.player2, 
        game_id: chessId, 
        player1_score: 1, 
        player2_score: 0, 
        winner_id: userIds.player5,
        played_at: oneWeekAgo
      },
      { 
        player1_id: userIds.player1, 
        player2_id: userIds.player4, 
        game_id: chessId, 
        player1_score: 1, 
        player2_score: 0, 
        winner_id: userIds.player1,
        played_at: yesterday
      }
    ]);
    console.log('Mock matches added');
    
    console.log('All mock data added successfully!');
    
  } catch (error) {
    console.error('Error adding mock data:', error);
  } finally {
    // Close database connection
    await sequelize.close();
  }
}

// Run the function
addMockData();
EOF
fi

# Check if main.js exists, if not create it
if [ ! -f "main.js" ]; then
    print_message "Creating main.js file..."
    
    # Create the file
    cat > main.js << 'EOF'
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { sequelize } = require('./src/models');

// Import routes
const authRoutes = require('./routes/auth');
const gamesRoutes = require('./routes/games');

const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Routes
app.use('/auth', authRoutes);
app.use('/games', gamesRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to ClassServer API' });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Start server
async function startServer() {
  try {
    // Test database connection
    await sequelize.authenticate();
    console.log('Database connection established successfully');
    
    // Start server
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Unable to connect to the database:', error);
  }
}

startServer();
EOF
fi

# Check if the games router exists
if [ ! -f "routes/games.js" ]; then
    print_message "Creating games router..."
    
    # Create routes directory if it doesn't exist
    mkdir -p routes
    
    # Create the router
    cat > routes/games.js << 'EOF'
const express = require('express');
const router = express.Router();
const { User, Game, UserElo } = require('../src/models');
const { Op } = require('sequelize');

/**
 * @route GET /games
 * @desc Get all game types
 * @access Public
 */
router.get('/', async (req, res) => {
  try {
    const games = await Game.findAll({
      where: { active: true },
      attributes: ['id', 'name', 'description']
    });
    
    res.json(games);
  } catch (error) {
    console.error('Error fetching games:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

/**
 * @route GET /games/leaderboard/:gameType
 * @desc Get leaderboard for a specific game type
 * @access Public
 */
router.get('/leaderboard/:gameType', async (req, res) => {
  try {
    const { gameType } = req.params;
    
    // Find the game by name
    const game = await Game.findOne({
      where: { 
        name: gameType,
        active: true
      }
    });
    
    if (!game) {
      return res.status(404).json({ message: `Game type '${gameType}' not found` });
    }
    
    // Get user ELO ratings for this game, ordered by rating
    const userElos = await UserElo.findAll({
      where: { game_id: game.id },
      include: [
        {
          model: User,
          attributes: ['id', 'username']
        }
      ],
      order: [['rating', 'DESC']]
    });
    
    // Format the response
    const leaderboard = userElos.map((elo, index) => ({
      rank: index + 1,
      player_id: elo.User.id,
      username: elo.User.username,
      rating: elo.rating,
      wins: elo.wins,
      losses: elo.losses
    }));
    
    res.json({
      game_type: gameType,
      entries: leaderboard
    });
    
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
EOF
fi

# Create a simple auth router if it doesn't exist
if [ ! -f "routes/auth.js" ]; then
    print_message "Creating auth router..."
    
    cat > routes/auth.js << 'EOF'
const express = require('express');
const router = express.Router();
const { User } = require('../src/models');

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

module.exports = router;
EOF
fi

# Install required npm packages
print_message "Installing required npm packages..."
npm install --save express sequelize pg pg-hstore cors morgan

# Export database environment variables for the script
export DB_NAME="$DB_NAME"
export DB_USER="$DB_USER"

# Run the mock data script
print_message "Running mock data script..."
node src/scripts/add_mock_data.js

# Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend || {
    print_warning "Failed to restart backend service. It may not be set up as a systemd service yet."
}

print_message "Mock players added successfully!"
print_message "If you encountered any database connection issues, you may need to:"
print_message "1. Check if PostgreSQL is running: sudo systemctl status postgresql"
print_message "2. Verify PostgreSQL authentication settings in pg_hba.conf"
print_message "3. Manually create the user and database:"
print_message "   sudo -u postgres psql -c \"CREATE USER classserver WITH PASSWORD 'classserver';\""
print_message "   sudo -u postgres psql -c \"CREATE DATABASE classserver OWNER classserver;\"" 