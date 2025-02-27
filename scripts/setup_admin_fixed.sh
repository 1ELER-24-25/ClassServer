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

# Create directories for components
print_message "Creating component directories..."
mkdir -p components
mkdir -p src

# Create src/index.js file first
print_message "Creating src/index.js file..."
cat > src/index.js << 'EOF'
const express = require("express");
const cors = require("cors");
const morgan = require("morgan");
const { sequelize } = require("./models");
const { router: adminRouter } = require("../adminSetup");

// Import routes
const authRoutes = require("../routes/auth");
const gamesRoutes = require("../routes/games");

const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

// Mount the admin panel
app.use("/admin", adminRouter);

// Routes
app.use("/auth", authRoutes);
app.use("/games", gamesRoutes);

// Root route
app.get("/", (req, res) => {
  res.json({ 
    message: "Welcome to ClassServer API",
    adminPanel: `${req.protocol}://${req.get("host")}/admin`
  });
});

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "healthy" });
});

// Start server
async function startServer() {
  try {
    // Test database connection
    await sequelize.authenticate();
    console.log("Database connection established successfully");
    
    // Start server
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`Admin panel available at: http://localhost:${PORT}/admin`);
    });
  } catch (error) {
    console.error("Unable to connect to the database:", error);
  }
}

startServer();
EOF

# Create AdminJS setup file
print_message "Creating AdminJS configuration..."
cat > adminSetup.js << 'EOF'
const AdminJS = require('adminjs');
const AdminJSExpress = require('@adminjs/express');
const AdminJSSequelize = require('@adminjs/sequelize');
const session = require('express-session');
const { sequelize, User, Game, Match, UserElo } = require('./src/models');

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

module.exports = { adminJs, router };
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
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { sequelize } = require('./src/models');
const { router: adminRouter } = require('./adminSetup');

// Import routes
const authRoutes = require('./routes/auth');
const gamesRoutes = require('./routes/games');

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