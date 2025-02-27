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