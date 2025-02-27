#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Adding sample data to the database..."

# Navigate to backend directory
cd /opt/ClassServer/backend

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
print_message "Running script to add sample data..."
node add_sample_data.js

# Clean up
print_message "Cleaning up..."
rm add_sample_data.js

print_success "Sample data added successfully!"
print_message "You can now see the sample data in the admin panel at: http://localhost:8000/admin"
print_message "The sample data includes:"
print_message "  - 4 users: john_doe, jane_smith, bob_johnson, alice_williams"
print_message "  - 4 games: Chess, Ping Pong, Foosball, Darts"
print_message "  - 8 matches with various scores and dates"
print_message "  - 16 ELO ratings for all users across all games" 