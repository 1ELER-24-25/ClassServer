#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Fixing src/index.js..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Fix src/index.js
print_message "Updating src/index.js..."
cat > src/index.js << 'EOF'
import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import db from './models/index.js';
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
    await db.sequelize.authenticate();
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

// Call the function to start the server
startServer();
EOF

print_success "src/index.js fixed successfully"

# Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend || {
    print_warning "Failed to restart backend service. It may not be set up as a systemd service yet."
    print_message "You can start the backend manually with: cd /opt/ClassServer/backend && node src/index.js"
}

print_success "Backend service restarted successfully!" 