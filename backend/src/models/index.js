const { Sequelize } = require('sequelize');
const config = require('../config/database');

const sequelize = new Sequelize(config.database, config.username, config.password, {
  host: config.host,
  dialect: config.dialect,
  logging: false
});

const User = require('./user')(sequelize);
const Game = require('./game')(sequelize);
const Match = require('./match')(sequelize);
const UserElo = require('./userElo')(sequelize);

// Define associations
User.hasMany(Match, { foreignKey: 'player1_id' });
User.hasMany(Match, { foreignKey: 'player2_id' });
User.hasMany(UserElo);

Game.hasMany(Match);
Game.hasMany(UserElo);

Match.belongsTo(User, { as: 'player1', foreignKey: 'player1_id' });
Match.belongsTo(User, { as: 'player2', foreignKey: 'player2_id' });
Match.belongsTo(Game);

UserElo.belongsTo(User);
UserElo.belongsTo(Game);

module.exports = {
  sequelize,
  User,
  Game,
  Match,
  UserElo
}; 