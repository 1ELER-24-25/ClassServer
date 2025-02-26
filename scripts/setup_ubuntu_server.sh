#!/bin/bash

# Exit on any error
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    echo -e "${GREEN}[Setup] ${NC}$1"
}

print_warning() {
    echo -e "${YELLOW}[Warning] ${NC}$1"
}

print_error() {
    echo -e "${RED}[Error] ${NC}$1"
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Get environment variables
read -p "Enter PostgreSQL password for classserver user: " DB_PASSWORD
read -p "Enter domain name (e.g., game.example.com): " DOMAIN_NAME
read -p "Enter email for SSL certificate: " EMAIL

# Update system
print_message "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
print_message "Installing required packages..."
apt-get install -y \
    postgresql \
    nginx \
    certbot \
    python3-certbot-nginx \
    python3-pip \
    python3-venv \
    git \
    nodejs \
    npm \
    ufw

# Configure PostgreSQL
print_message "Configuring PostgreSQL..."
sudo -u postgres psql -c "DO \$do\$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'classserver') THEN CREATE USER classserver WITH PASSWORD '$DB_PASSWORD'; END IF; END \$do\$;" || {
    print_error "Failed to create PostgreSQL user"
    exit 1
}
sudo -u postgres psql -c "CREATE DATABASE classserver WITH OWNER classserver;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE classserver TO classserver;"

# Configure Nginx
print_message "Configuring Nginx..."
cat > /etc/nginx/sites-available/classserver << EOF
server {
    server_name $DOMAIN_NAME;

    # Serve static frontend files
    location / {
        root /opt/ClassServer/frontend/dist;  # Vite builds to 'dist' by default
        try_files \$uri \$uri/ /index.html;
        add_header Cache-Control "public, max-age=3600";
    }

    # Backend API proxy
    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/classserver /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx

# Configure SSL with Certbot
print_message "Configuring SSL certificate..."
certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos -m $EMAIL --redirect

# Configure firewall
print_message "Configuring firewall..."
ufw allow 'Nginx Full'
ufw allow OpenSSH
ufw --force enable

# Clone repository
print_message "Cloning repository..."
read -p "Enter GitHub repository URL (e.g., https://github.com/1ELER-24-25/ClassServer.git): " REPO_URL
cd /opt
git clone "$REPO_URL" ClassServer || {
    print_error "Failed to clone repository"
    exit 1
}
cd ClassServer

# Setup Python backend
print_message "Setting up Python backend..."
if [ ! -f requirements.txt ]; then
    print_error "requirements.txt not found in /opt/ClassServer"
    exit 1
fi
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt || {
    print_error "Failed to install Python dependencies"
    exit 1
}
deactivate

# Create backend service
cat > /etc/systemd/system/classserver-backend.service << EOF
[Unit]
Description=ClassServer Backend
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/ClassServer/backend
Environment="PATH=/opt/ClassServer/venv/bin"
Environment="DATABASE_URL=postgresql://classserver:$DB_PASSWORD@localhost/classserver"
ExecStart=/opt/ClassServer/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000

[Install]
WantedBy=multi-user.target
EOF

# Setup frontend
print_message "Setting up frontend..."
cd frontend
npm install || {
    print_error "Failed to install frontend dependencies"
    exit 1
}
npm run build || {
    print_error "Failed to build frontend"
    exit 1
}

# Set proper permissions
print_message "Setting permissions..."
chown -R www-data:www-data /opt/ClassServer
chmod -R 755 /opt/ClassServer

# Start backend service
print_message "Starting backend service..."
systemctl daemon-reload
systemctl enable classserver-backend
systemctl start classserver-backend

# Create backup script
print_message "Creating backup script..."
cat > /opt/ClassServer/scripts/backup.sh << EOF
#!/bin/bash
BACKUP_DIR="/opt/ClassServer/backups"
TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")
mkdir -p \$BACKUP_DIR

# Backup database
pg_dump -U classserver classserver > \$BACKUP_DIR/db_\$TIMESTAMP.sql

# Backup uploads directory if exists
if [ -d "/opt/ClassServer/backend/uploads" ]; then
    tar -czf \$BACKUP_DIR/uploads_\$TIMESTAMP.tar.gz /opt/ClassServer/backend/uploads
fi

# Keep only last 7 days of backups
find \$BACKUP_DIR -type f -mtime +7 -delete
EOF

chmod +x /opt/ClassServer/scripts/backup.sh

# Add backup cron job
(crontab -l 2>/dev/null; echo "0 3 * * * /opt/ClassServer/scripts/backup.sh") | crontab -

print_message "Installation completed successfully!"
print_message "Your server is now running at https://$DOMAIN_NAME"
print_message "Please make sure to:"
print_message "1. Update the database connection string in the backend configuration"
print_message "2. Configure your domain's DNS settings to point to this server"
print_message "3. Test the SSL certificate renewal with: certbot renew --dry-run"
print_warning "Keep your database password safe: $DB_PASSWORD" 