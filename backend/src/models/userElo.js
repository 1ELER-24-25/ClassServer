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