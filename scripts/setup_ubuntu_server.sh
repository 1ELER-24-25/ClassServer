#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${YELLOW}[*] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[+] $1${NC}"
}

print_error() {
    echo -e "${RED}[-] $1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Update package list
print_status "Updating package list..."
apt-get update

# Install essential tools
print_status "Installing essential tools..."
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3-pip \
    ufw \
    fail2ban

# Install and configure PostgreSQL
print_status "Installing PostgreSQL..."
if ! command_exists psql; then
    apt-get install -y postgresql postgresql-contrib
    systemctl enable postgresql
    systemctl start postgresql
    print_success "PostgreSQL installed and started"

    # Create database and user
    print_status "Setting up PostgreSQL user and database..."
    sudo -u postgres psql -c "CREATE USER classserver WITH PASSWORD 'changeme' CREATEDB;"
    sudo -u postgres psql -c "CREATE DATABASE classserver OWNER classserver;"
    print_success "PostgreSQL user and database created"
else
    print_status "PostgreSQL is already installed"
fi

# Install Node.js and npm
print_status "Installing Node.js and npm..."
if ! command_exists node; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    print_success "Node.js installed: $(node --version)"
    print_success "npm installed: $(npm --version)"
else
    print_status "Node.js is already installed: $(node --version)"
fi

# Install global npm packages
print_status "Installing global npm packages..."
npm install -g pm2 sequelize-cli

# Configure firewall
print_status "Configuring firewall..."
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp  # Backend API
ufw allow 5173/tcp  # Frontend development
ufw --force enable

# Install and configure Fail2ban
print_status "Configuring Fail2ban..."
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban

# Create project directory structure
print_status "Creating project directory structure..."
PROJECT_DIR="/opt/classserver"
mkdir -p $PROJECT_DIR
chown -R $SUDO_USER:$SUDO_USER $PROJECT_DIR

# Create systemd service for the backend
print_status "Creating systemd service..."
cat > /etc/systemd/system/classserver.service << EOL
[Unit]
Description=ClassServer Backend
After=network.target postgresql.service

[Service]
Type=simple
User=$SUDO_USER
WorkingDirectory=$PROJECT_DIR/backend
ExecStart=/usr/bin/npm start
Restart=always
Environment=NODE_ENV=production
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd
systemctl daemon-reload

# Setup environment variables
print_status "Setting up environment variables..."
cat > $PROJECT_DIR/.env << EOL
# Server Configuration
PORT=3000
NODE_ENV=production

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=classserver
DB_USER=classserver
DB_PASSWORD=changeme

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100

# Game Configuration
MAX_USERS=100
MAX_CONCURRENT_GAMES=10
MAX_API_RESPONSE_TIME_MS=500

# Logging
LOG_LEVEL=info
LOG_FILE_PATH=/var/log/classserver/app.log
EOL

# Create log directory
mkdir -p /var/log/classserver
chown -R $SUDO_USER:$SUDO_USER /var/log/classserver

# Final setup steps
print_status "Performing final setup steps..."
systemctl enable classserver

# Print setup summary
print_success "Installation completed!"
echo -e "\nSetup Summary:"
echo "---------------"
echo "PostgreSQL Database: classserver"
echo "PostgreSQL User: classserver"
echo "Project Directory: $PROJECT_DIR"
echo "Backend Port: 3000"
echo "Frontend Development Port: 5173"
echo "Log Directory: /var/log/classserver"
echo -e "\nNext steps:"
echo "1. Update database password in .env file"
echo "2. Clone your project repository to $PROJECT_DIR"
echo "3. Run 'npm install' in both frontend and backend directories"
echo "4. Run database migrations: 'npm run migrate'"
echo "5. Start the service: 'systemctl start classserver'"
echo -e "\nNote: Remember to secure your server and change default passwords!" 