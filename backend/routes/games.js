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