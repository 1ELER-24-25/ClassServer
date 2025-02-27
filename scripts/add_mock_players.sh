#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Adding mock players to the database..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Create scripts directory if it doesn't exist
mkdir -p src/scripts

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

# Check if the games router exists
if [ ! -f "routes/games.js" ]; then
    print_message "Creating games router..."
    
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

# Update main.js to include the games router
if ! grep -q "gamesRoutes" main.js; then
    print_message "Updating main.js to include games router..."
    
    # Create a temporary file
    cat > main.js.tmp << 'EOF'
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
    
    # Replace the original file
    mv main.js.tmp main.js
fi

# Run the mock data script
print_message "Running mock data script..."
node src/scripts/add_mock_data.js

# Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend

print_message "Mock players added successfully!" 