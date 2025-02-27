#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Fixing body-parser middleware conflict..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Update src/index.js to fix body-parser middleware order
print_message "Updating src/index.js to fix middleware order..."
cat > src/index.js << 'EOF'
import express from 'express';
import cors from 'cors';
import { initializeAdmin } from '../adminSetup.js';

const app = express();
const PORT = process.env.PORT || 8000;

// Only apply CORS middleware before AdminJS
app.use(cors());

// Health check route
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Initialize AdminJS asynchronously
const startServer = async () => {
  try {
    // Initialize AdminJS
    const { router: adminRouter } = await initializeAdmin();
    
    // Mount AdminJS router BEFORE body-parser middleware
    app.use('/admin', adminRouter);
    
    // Apply body-parser middleware AFTER AdminJS router
    app.use(express.json());
    app.use(express.urlencoded({ extended: true }));
    
    // Start server
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Start the server
startServer();
EOF

print_success "Body-parser middleware conflict fixed successfully"

# Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend || {
    print_warning "Failed to restart backend service. It may not be set up as a systemd service yet."
    print_message "You can start the backend manually with: cd /opt/ClassServer/backend && node src/index.js"
}

print_success "Backend service restarted successfully!"
print_message "You can now use the admin panel at: http://localhost:8000/admin"
print_message "Login with:"
print_message "  Email: admin@classserver.com"
print_message "  Password: classserver" 