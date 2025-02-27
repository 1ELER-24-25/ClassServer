#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Converting model files to ES Modules..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Fix game.js
print_message "Fixing src/models/game.js..."
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
print_message "Fixing src/models/match.js..."
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
print_message "Fixing src/models/user.js..."
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
print_message "Fixing src/models/userElo.js..."
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
print_message "Fixing src/models/index.js..."
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

print_success "Model files converted to ES Modules successfully"

# Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend || {
    print_warning "Failed to restart backend service. It may not be set up as a systemd service yet."
    print_message "You can start the backend manually with: cd /opt/ClassServer/backend && node src/index.js"
}

print_success "Backend service restarted successfully!" 