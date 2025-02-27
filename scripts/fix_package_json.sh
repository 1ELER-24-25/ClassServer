#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Fixing package.json to support ES Modules..."

# Navigate to backend directory
cd /opt/ClassServer/backend

# Backup the original file
cp package.json package.json.bak

# Add type: module to package.json
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
    "@adminjs/express": "^6.1.1",
    "@adminjs/sequelize": "^4.1.1",
    "adminjs": "^7.8.15",
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

print_success "package.json updated to support ES Modules"

# Restart the backend service
print_message "Restarting backend service..."
systemctl restart classserver-backend || {
    print_warning "Failed to restart backend service. It may not be set up as a systemd service yet."
    print_message "You can start the backend manually with: cd /opt/ClassServer/backend && node main.js"
}

print_success "Backend service restarted successfully!" 