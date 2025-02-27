#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Setting up AdminJS admin panel for ClassServer..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Install required packages
print_message "Installing AdminJS and required packages..."
npm install --save adminjs @adminjs/express @adminjs/sequelize express-formidable express-session

# Update package.json to support ES Modules
print_message "Updating package.json to support ES Modules..."
if [ -f "package.json" ]; then
    # Backup the original file
    cp package.json package.json.bak
    
    # Update package.json to include type: module
    jq '. + {"type": "module"}' package.json > package.json.tmp && mv package.json.tmp package.json
    print_message "package.json updated to support ES Modules"
else
    print_warning "package.json not found. Creating a new one..."
    cat > package.json << 'EOF'
{
  "name": "@classserver/backend",
  "version": "1.0.0",
  "description": "Backend server for ClassServer",
  "main": "src/index.js",
  "type": "module",
  "scripts": {
    "start": "nodemon src/index.js",
    "build": "babel src -d dist",
    "test": "jest",
    "lint": "eslint src/",
    "migrate": "sequelize-cli db:migrate",
    "seed": "sequelize-cli db:seed:all"
  },
  "dependencies": {
    "adminjs": "^7.8.15",
    "@adminjs/express": "^6.1.1",
    "@adminjs/sequelize": "^4.1.1",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.21.2",
    "express-formidable": "^1.2.0",
    "express-session": "^1.18.1",
    "express-validator": "^7.0.1",
    "morgan": "^1.10.0",
    "pg": "^8.13.3",
    "pg-hstore": "^2.3.4",
    "sequelize": "^6.37.5",
    "winston": "^3.11.0"
  },
  "devDependencies": {
    "@babel/cli": "^7.23.9",
    "@babel/core": "^7.23.9",
    "@babel/preset-env": "^7.23.9",
    "eslint": "^8.56.0",
    "jest": "^29.7.0",
    "nodemon": "^3.0.3",
    "sequelize-cli": "^6.6.2",
    "supertest": "^6.3.4"
  }
}
EOF
fi

# Create directories for components
print_message "Creating component directories..."
mkdir -p components
mkdir -p src

# Create src/index.js file first
print_message "Creating src/index.js file..."
cat > src/index.js << 'EOF'
import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import { sequelize } from './models/index.js';
import { router as adminRouter } from '../adminSetup.js';

// Import routes
import authRoutes from '../routes/auth.js';
import gamesRoutes from '../routes/games.js';

const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Mount the admin panel
app.use('/admin', adminRouter);

// Routes
app.use('/auth', authRoutes);
app.use('/games', gamesRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({ 
    message: 'Welcome to ClassServer API',
    adminPanel: `${req.protocol}://${req.get('host')}/admin`
  });
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
      console.log(`Admin panel available at: http://localhost:${PORT}/admin`);
    });
  } catch (error) {
    console.error('Unable to connect to the database:', error);
  }
}

startServer();
EOF

# Update model files to use ES Modules
print_message "Updating model files to use ES Modules..."
if [ -d "src/models" ]; then
    # Update index.js
    if [ -f "src/models/index.js" ]; then
        print_message "Updating src/models/index.js..."
        cp src/models/index.js src/models/index.js.bak
        
        # Convert to ES Modules
        cat > src/models/index.js << 'EOF'
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import Sequelize from 'sequelize';
import process from 'process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const basename = path.basename(__filename);
const env = process.env.NODE_ENV || 'development';
const config = {
  username: process.env.DB_USER || 'classserver',
  password: process.env.DB_PASSWORD || 'classserver',
  database: process.env.DB_NAME || 'classserver',
  host: process.env.DB_HOST || 'localhost',
  dialect: 'postgres'
};
const db = {};

let sequelize;
if (config.use_env_variable) {
  sequelize = new Sequelize(process.env[config.use_env_variable], config);
} else {
  sequelize = new Sequelize(config.database, config.username, config.password, config);
}

// Import all model files
const modelFiles = fs.readdirSync(__dirname)
  .filter(file => {
    return (
      file.indexOf('.') !== 0 &&
      file !== basename &&
      file.slice(-3) === '.js' &&
      file.indexOf('.test.js') === -1
    );
  });

// Dynamic imports for all models
const importModels = async () => {
  for (const file of modelFiles) {
    const modulePath = `file://${path.join(__dirname, file)}`;
    const model = await import(modulePath);
    db[model.default.name] = model.default;
  }
};

// Initialize models
const initializeModels = async () => {
  await importModels();
  
  Object.keys(db).forEach(modelName => {
    if (db[modelName].associate) {
      db[modelName].associate(db);
    }
  });
};

// Call initialize (this is async but we'll handle it in the application)
initializeModels();

db.sequelize = sequelize;
db.Sequelize = Sequelize;

export default db;
export { sequelize, Sequelize };
EOF
        print_message "src/models/index.js updated to use ES Modules"
    else
        print_warning "src/models/index.js not found. Skipping update."
    fi
    
    # Update other model files
    for model_file in src/models/*.js; do
        if [ "$model_file" != "src/models/index.js" ] && [ -f "$model_file" ]; then
            print_message "Updating $model_file..."
            cp "$model_file" "${model_file}.bak"
            
            # Convert to ES Modules (simplified approach)
            sed -i 's/const { Model } = require/import { Model } from/g' "$model_file"
            sed -i 's/module.exports = /export default /g' "$model_file"
        fi
    done
else
    print_warning "src/models directory not found. Skipping model updates."
fi

# Update route files to use ES Modules
print_message "Updating route files to use ES Modules..."
if [ -d "routes" ]; then
    for route_file in routes/*.js; do
        if [ -f "$route_file" ]; then
            print_message "Updating $route_file..."
            cp "$route_file" "${route_file}.bak"
            
            # Convert to ES Modules (simplified approach)
            sed -i 's/const express = require/import express from/g' "$route_file"
            sed -i 's/const router = express.Router()/const router = express.Router()/g' "$route_file"
            sed -i 's/const { [^}]* } = require/import { Model } from/g' "$route_file"
            sed -i 's/module.exports = router/export default router/g' "$route_file"
        fi
    done
else
    print_warning "routes directory not found. Skipping route updates."
fi

# Create AdminJS setup file
print_message "Creating AdminJS configuration..."
cat > adminSetup.js << 'EOF'
import AdminJS from 'adminjs';
import AdminJSExpress from '@adminjs/express';
import AdminJSSequelize from '@adminjs/sequelize';
import session from 'express-session';
import { sequelize, User, Game, Match, UserElo } from './src/models/index.js';

// Register Sequelize adapter
AdminJS.registerAdapter(AdminJSSequelize);

// Define AdminJS instance
const adminJs = new AdminJS({
  databases: [sequelize],
  resources: [
    {
      resource: User,
      options: {
        navigation: { name: 'Users Management', icon: 'User' },
        properties: {
          created_at: { isVisible: { list: true, filter: true, show: true, edit: false } },
          updated_at: { isVisible: { list: true, filter: true, show: true, edit: false } }
        }
      },
    },
    {
      resource: Game,
      options: {
        navigation: { name: 'Games Management', icon: 'GameController' },
        properties: {
          created_at: { isVisible: { list: true, filter: true, show: true, edit: false } },
          updated_at: { isVisible: { list: true, filter: true, show: true, edit: false } }
        }
      },
    },
    {
      resource: Match,
      options: {
        navigation: { name: 'Matches', icon: 'Activity' },
        properties: {
          played_at: { isVisible: { list: true, filter: true, show: true, edit: true } },
          created_at: { isVisible: { list: true, filter: true, show: true, edit: false } },
          updated_at: { isVisible: { list: true, filter: true, show: true, edit: false } }
        }
      },
    },
    {
      resource: UserElo,
      options: {
        navigation: { name: 'ELO Ratings', icon: 'Star' },
        properties: {
          created_at: { isVisible: { list: true, filter: true, show: true, edit: false } },
          updated_at: { isVisible: { list: true, filter: true, show: true, edit: false } }
        }
      },
    },
  ],
  rootPath: '/admin',
  branding: {
    companyName: 'ClassServer Admin',
    logo: false,
    favicon: '/favicon.ico',
  },
  dashboard: {
    component: AdminJS.bundle('./components/dashboard')
  }
});

// Create admin credentials - in production, use environment variables
const DEFAULT_ADMIN = {
  email: 'admin@classserver.com',
  password: 'classserver',
}

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

export { adminJs, router };
EOF

# Create dashboard component
print_message "Creating dashboard component..."
cat > components/dashboard.jsx << 'EOF'
import React from 'react';
import { Box, H2, H4, Text } from '@adminjs/design-system';

const Dashboard = () => {
  return (
    <Box variant="grey">
      <Box variant="white" style={{ padding: '20px' }}>
        <H2>Welcome to ClassServer Admin Panel</H2>
        <Text>This is your admin dashboard for managing the ClassServer application.</Text>
        
        <Box style={{ display: 'flex', justifyContent: 'space-between', marginTop: '20px' }}>
          <Box style={{ flex: 1, padding: '15px', backgroundColor: '#f5f5f5', margin: '10px', borderRadius: '5px' }}>
            <H4>Users</H4>
            <Text>Manage player accounts, view and edit user information.</Text>
          </Box>
          
          <Box style={{ flex: 1, padding: '15px', backgroundColor: '#f5f5f5', margin: '10px', borderRadius: '5px' }}>
            <H4>Games</H4>
            <Text>Add, edit, or remove game types in the system.</Text>
          </Box>
          
          <Box style={{ flex: 1, padding: '15px', backgroundColor: '#f5f5f5', margin: '10px', borderRadius: '5px' }}>
            <H4>Matches</H4>
            <Text>View match history, scores, and game statistics.</Text>
          </Box>
        </Box>
        
        <Box style={{ marginTop: '20px' }}>
          <H4>ELO Ratings</H4>
          <Text>View and manage player ratings across different games.</Text>
        </Box>
      </Box>
    </Box>
  );
};

export default Dashboard;
EOF

# Update main.js to include AdminJS
print_message "Updating main.js to include AdminJS..."
if [ -f "main.js" ]; then
    # Backup the original file
    cp main.js main.js.bak
    
    # Create a new main.js with AdminJS integration
    cat > main.js << 'EOF'
import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import { sequelize } from './src/models/index.js';
import { router as adminRouter } from './adminSetup.js';

// Import routes
import authRoutes from './routes/auth.js';
import gamesRoutes from './routes/games.js';

const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Mount the admin panel
app.use('/admin', adminRouter);

// Routes
app.use('/auth', authRoutes);
app.use('/games', gamesRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({ 
    message: 'Welcome to ClassServer API',
    adminPanel: `${req.protocol}://${req.get('host')}/admin`
  });
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
      console.log(`Admin panel available at: http://localhost:${PORT}/admin`);
    });
  } catch (error) {
    console.error('Unable to connect to the database:', error);
  }
}

startServer();
EOF
    print_message "main.js updated successfully. Original backed up as main.js.bak"
else
    print_warning "main.js not found. Skipping update."
fi

# Update frontend to include admin link
print_message "Updating frontend to include admin link..."
FRONTEND_DIR="/opt/ClassServer/frontend"
if [ -d "$FRONTEND_DIR/src" ]; then
    # Check if HomePage component exists
    if [ -f "$FRONTEND_DIR/src/components/HomePage.jsx" ]; then
        # Backup the original file
        cp "$FRONTEND_DIR/src/components/HomePage.jsx" "$FRONTEND_DIR/src/components/HomePage.jsx.bak"
        
        # Add admin link to HomePage
        print_message "Adding admin link to HomePage component..."
        # This is a simplified approach - in a real scenario, you might want to use a more robust method
        # to modify React components
        cat > "$FRONTEND_DIR/src/components/HomePage.jsx" << 'EOF'
import React from 'react';
import { Link } from 'react-router-dom';
import './HomePage.css';

const HomePage = () => {
  return (
    <div className="home-container">
      <header className="home-header">
        <h1>ClassServer</h1>
        <p>Board Game Competition System</p>
      </header>
      
      <main className="home-main">
        {/* Your existing content */}
        
        <div className="admin-access">
          <h2>Administration</h2>
          <p>Access the admin panel to manage users, games, and matches.</p>
          <a 
            href="/admin" 
            className="admin-button"
            target="_blank" 
            rel="noopener noreferrer"
          >
            Admin Panel
          </a>
        </div>
      </main>
    </div>
  );
};

export default HomePage;
EOF
        
        # Add CSS for admin button
        print_message "Adding CSS for admin button..."
        if [ -f "$FRONTEND_DIR/src/components/HomePage.css" ]; then
            # Append CSS to existing file
            cat >> "$FRONTEND_DIR/src/components/HomePage.css" << 'EOF'

/* Admin panel styles */
.admin-button {
  display: inline-block;
  background-color: #3498db;
  color: white;
  padding: 10px 20px;
  border-radius: 4px;
  text-decoration: none;
  font-weight: bold;
  margin-top: 10px;
  transition: background-color 0.3s;
}

.admin-button:hover {
  background-color: #2980b9;
}

.admin-access {
  margin-top: 40px;
  padding: 20px;
  background-color: #f8f9fa;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}
EOF
        else
            # Create new CSS file
            cat > "$FRONTEND_DIR/src/components/HomePage.css" << 'EOF'
/* HomePage styles */
.home-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.home-header {
  text-align: center;
  margin-bottom: 40px;
}

.home-header h1 {
  font-size: 2.5rem;
  color: #2c3e50;
}

.home-main {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Admin panel styles */
.admin-button {
  display: inline-block;
  background-color: #3498db;
  color: white;
  padding: 10px 20px;
  border-radius: 4px;
  text-decoration: none;
  font-weight: bold;
  margin-top: 10px;
  transition: background-color 0.3s;
}

.admin-button:hover {
  background-color: #2980b9;
}

.admin-access {
  margin-top: 40px;
  padding: 20px;
  background-color: #f8f9fa;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}
EOF
        fi
        
        print_message "Frontend updated successfully. Original HomePage backed up as HomePage.jsx.bak"
    else
        print_warning "HomePage component not found. Skipping frontend update."
    fi
else
    print_warning "Frontend directory not found. Skipping frontend update."
fi

# Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend || {
    print_warning "Failed to restart backend service. It may not be set up as a systemd service yet."
    print_message "You can start the backend manually with: cd /opt/ClassServer/backend && node main.js"
}

print_success "AdminJS admin panel setup completed successfully!"
print_message "You can access the admin panel at: http://your-server-address:8000/admin"
print_message "Default admin credentials:"
print_message "  Email: admin@classserver.com"
print_message "  Password: classserver"
print_message "Please change these credentials in production!"