#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Fixing route files..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Fix auth.js
print_message "Fixing routes/auth.js..."
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
print_message "Fixing routes/games.js..."
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

print_success "Route files fixed successfully"

# Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend || {
    print_warning "Failed to restart backend service. It may not be set up as a systemd service yet."
    print_message "You can start the backend manually with: cd /opt/ClassServer/backend && node main.js"
}

print_success "Backend service restarted successfully!" 