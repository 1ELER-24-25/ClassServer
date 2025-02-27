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

# Function to validate IP address
validate_ip() {
    if echo "$1" | grep -qP '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$'; then
        local IFS='.'
        local -a ip=($1)
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        return $?
    fi
    return 1
}

# Function to validate domain name format (relaxed for local use)
validate_domain() {
    if ! echo "$1" | grep -qP '^[a-zA-Z0-9.-]+\.[a-zA-Z0-9-]{2,}$|^[a-zA-Z0-9-]+$'; then
        return 1
    fi
    return 0
}

# Get and validate environment variables
while true; do
    read -s -p "Enter PostgreSQL password for classserver user: " DB_PASSWORD
    echo
    if [ ${#DB_PASSWORD} -lt 8 ]; then
        print_error "Password must be at least 8 characters long"
        continue
    fi
    break
done

while true; do
    read -p "Enter server address (IP or local domain, e.g., 192.168.1.100 or local.classserver): " SERVER_ADDRESS
    if ! validate_ip "$SERVER_ADDRESS" && ! validate_domain "$SERVER_ADDRESS"; then
        print_error "Invalid address format. Use an IP (e.g., 192.168.1.100) or local domain (e.g., local.classserver)"
        continue
    fi
    break
done

# Create a backup of existing configuration if any
if [ -d "/opt/ClassServer" ]; then
    BACKUP_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    print_warning "Existing ClassServer installation found. Creating backup..."
    tar -czf "/opt/classserver_backup_${BACKUP_TIMESTAMP}.tar.gz" /opt/ClassServer
fi

# Copy current repository to /opt
print_message "Copying files to /opt/ClassServer..."
cp -r "$(dirname "$(dirname "$0")")" /opt/ClassServer || {
    print_error "Failed to copy files to /opt/ClassServer"
    exit 1
}

# Update system
print_message "Updating system packages..."
apt-get update || {
    print_error "Failed to update package list"
    exit 1
}
apt-get upgrade -y || {
    print_error "Failed to upgrade packages"
    exit 1
}

# Install required packages (without SSL-related packages)
print_message "Installing required packages..."
apt-get install -y \
    postgresql \
    nginx \
    python3-pip \
    python3-venv \
    git \
    ufw || {
    print_error "Failed to install required packages"
    exit 1
}

# Install Node.js 20.x
print_message "Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - || {
    print_error "Failed to setup Node.js repository"
    exit 1
}
apt-get install -y nodejs || {
    print_error "Failed to install Node.js"
    exit 1
}

# Start and enable PostgreSQL
print_message "Starting PostgreSQL server..."
systemctl start postgresql || {
    print_error "Failed to start PostgreSQL server"
    exit 1
}
systemctl enable postgresql || {
    print_error "Failed to enable PostgreSQL server"
    exit 1
}

# Configure PostgreSQL with error handling
print_message "Configuring PostgreSQL..."
sudo -u postgres psql -c "DO \$do\$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'classserver') THEN CREATE USER classserver WITH PASSWORD '$DB_PASSWORD'; END IF; END \$do\$;" || {
    print_error "Failed to create PostgreSQL user"
    exit 1
}
sudo -u postgres psql -c "CREATE DATABASE classserver WITH OWNER classserver;" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE classserver TO classserver;" || {
    print_error "Failed to grant privileges to PostgreSQL user"
    exit 1
}

# Create Nginx security configuration
cat > /etc/nginx/conf.d/security.conf << EOF
# Security settings
server_tokens off;
client_max_body_size 10M;
client_body_timeout 12;
client_header_timeout 12;
send_timeout 10;

# Rate limiting zone
limit_req_zone \$binary_remote_addr zone=api:10m rate=5r/s;
EOF

# Configure Nginx for HTTP only
print_message "Configuring Nginx..."
cat > /etc/nginx/sites-available/classserver << EOF
server {
    listen 80;
    server_name ${SERVER_ADDRESS};

    # Security headers (even for HTTP)
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    # Serve static frontend files
    location / {
        root /opt/ClassServer/frontend/dist;
        index index.html;
        try_files \$uri \$uri/ /index.html =404;
        add_header Cache-Control "public, max-age=3600";
    }

    # Backend API proxy
    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Rate limiting
        limit_req zone=api burst=10 nodelay;
        limit_req_status 429;
    }
}
EOF

# Configure Nginx
ln -sf /etc/nginx/sites-available/classserver /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
if ! nginx -t; then
    print_error "Nginx configuration test failed"
    exit 1
fi

# Restart Nginx
systemctl restart nginx || {
    print_error "Failed to restart Nginx"
    exit 1
}

# Configure firewall for HTTP only
print_message "Configuring firewall..."
ufw status verbose | grep -q "Status: active" && {
    print_warning "Firewall is already active. Adding rules..."
} || {
    print_message "Enabling firewall..."
    ufw --force enable
}

ufw allow 80/tcp || {
    print_error "Failed to add HTTP firewall rule"
    exit 1
}
ufw allow OpenSSH || {
    print_error "Failed to add SSH firewall rule"
    exit 1
}

# Setup Python backend with enhanced error handling
print_message "Setting up Python backend..."
if [ ! -f "/opt/ClassServer/requirements.txt" ]; then
    print_error "requirements.txt not found in /opt/ClassServer"
    print_warning "Please ensure the repository contains a requirements.txt file"
    exit 1
fi

# Create and activate virtual environment with error handling
print_message "Creating Python virtual environment..."
if ! python3 -m venv venv; then
    print_error "Failed to create Python virtual environment"
    exit 1
fi

source venv/bin/activate || {
    print_error "Failed to activate Python virtual environment"
    exit 1
}

# Upgrade pip and install dependencies
print_message "Upgrading pip and installing dependencies..."
python -m pip install --upgrade pip || {
    print_error "Failed to upgrade pip"
    exit 1
}

pip install -r /opt/ClassServer/requirements.txt || {
    print_error "Failed to install Python dependencies"
    print_warning "Check requirements.txt for any invalid packages"
    exit 1
}

deactivate

# Create backend service with enhanced security
print_message "Creating backend service..."
cat > /etc/systemd/system/classserver-backend.service << EOF
[Unit]
Description=ClassServer Backend
After=network.target postgresql.service
Requires=postgresql.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/ClassServer/backend
Environment="PATH=/opt/ClassServer/venv/bin"
Environment="DATABASE_URL=postgresql://classserver:$DB_PASSWORD@localhost/classserver"
ExecStart=/opt/ClassServer/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
StartLimitIntervalSec=60
StartLimitBurst=3

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=full
ProtectHome=yes
CapabilityBoundingSet=
AmbientCapabilities=
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
LockPersonality=yes

[Install]
WantedBy=multi-user.target
EOF

# Setup frontend with improved error handling
print_message "Setting up frontend..."
cd /opt/ClassServer/frontend || {
    print_error "Failed to change to frontend directory"
    exit 1
}

# Check for package.json
if [ ! -f "package.json" ]; then
    print_error "package.json not found in frontend directory"
    exit 1
fi

# Create necessary directories
print_message "Creating frontend directory structure..."
mkdir -p src/{components,hooks,pages,lib,types,components/layouts,components/auth,pages/auth,pages/admin}

# Create useAuth hook
print_message "Creating auth hook..."
cat > src/hooks/useAuth.ts << EOF
import { create } from 'zustand';

interface User {
  id: number;
  email: string;
  isAdmin: boolean;
}

interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isAdmin: boolean;
  login: (user: User) => void;
  logout: () => void;
}

export const useAuth = create<AuthState>((set) => ({
  user: null,
  isAuthenticated: false,
  isAdmin: false,
  login: (user) => set({ user, isAuthenticated: true, isAdmin: user.isAdmin }),
  logout: () => set({ user: null, isAuthenticated: false, isAdmin: false }),
}));
EOF

# Create minimal component files
print_message "Creating minimal component files..."
cat > src/components/layouts/AuthLayout.tsx << EOF
import React from 'react';
import { Outlet } from 'react-router-dom';

const AuthLayout: React.FC = () => {
  return (
    <div className="min-h-screen bg-gray-100">
      <div className="container mx-auto px-4 py-8">
        <Outlet />
      </div>
    </div>
  );
};

export default AuthLayout;
EOF

cat > src/components/auth/ProtectedRoute.tsx << EOF
import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '@hooks/useAuth';

const ProtectedRoute: React.FC = () => {
  const { isAuthenticated } = useAuth();
  return isAuthenticated ? <Outlet /> : <Navigate to="/login" />;
};

export default ProtectedRoute;
EOF

cat > src/components/auth/AdminRoute.tsx << EOF
import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '@hooks/useAuth';

const AdminRoute: React.FC = () => {
  const { isAdmin } = useAuth();
  return isAdmin ? <Outlet /> : <Navigate to="/" />;
};

export default AdminRoute;
EOF

# Create minimal page files
print_message "Creating minimal page files..."
for page in Register Dashboard Profile MatchHistory NotFound; do
  cat > src/pages/${page}.tsx << EOF
import React from 'react';

const ${page}: React.FC = () => {
  return <div>${page} Page</div>;
};

export default ${page};
EOF
done

# Create auth pages
cat > src/pages/auth/Register.tsx << EOF
import React from 'react';

const Register: React.FC = () => {
  return <div>Register Page</div>;
};

export default Register;
EOF

# Create admin pages
for page in Backup Games; do
  cat > src/pages/admin/${page}.tsx << EOF
import React from 'react';

const Admin${page}: React.FC = () => {
  return <div>Admin ${page} Page</div>;
};

export default Admin${page};
EOF
done

# Update App.tsx
print_message "Updating App.tsx..."
cat > src/App.tsx << EOF
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import AuthLayout from '@components/layouts/AuthLayout';
import Register from '@pages/auth/Register';
import Dashboard from '@pages/Dashboard';
import Profile from '@pages/Profile';
import MatchHistory from '@pages/MatchHistory';
import AdminBackup from '@pages/admin/Backup';
import AdminGames from '@pages/admin/Games';
import NotFound from '@pages/NotFound';
import ProtectedRoute from '@components/auth/ProtectedRoute';
import AdminRoute from '@components/auth/AdminRoute';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<AuthLayout />}>
          <Route path="/register" element={<Register />} />
          <Route element={<ProtectedRoute />}>
            <Route path="/" element={<Dashboard />} />
            <Route path="/profile" element={<Profile />} />
            <Route path="/matches" element={<MatchHistory />} />
            <Route element={<AdminRoute />}>
              <Route path="/admin/backup" element={<AdminBackup />} />
              <Route path="/admin/games" element={<AdminGames />} />
            </Route>
          </Route>
        </Route>
        <Route path="*" element={<NotFound />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
EOF

# Update package.json dependencies
print_message "Updating package.json..."
cat > package.json << EOF
{
  "name": "@classserver/frontend",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "lint": "eslint src --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.22.1",
    "zustand": "^4.5.1",
    "@heroicons/react": "^2.1.1"
  },
  "devDependencies": {
    "@types/react": "^18.2.56",
    "@types/react-dom": "^18.2.19",
    "@typescript-eslint/eslint-plugin": "^7.0.2",
    "@typescript-eslint/parser": "^7.0.2",
    "@vitejs/plugin-react": "^4.2.1",
    "autoprefixer": "^10.4.17",
    "eslint": "^8.56.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.5",
    "postcss": "^8.4.35",
    "tailwindcss": "^3.4.1",
    "typescript": "^5.2.2",
    "vite": "^5.1.4"
  }
}
EOF

# Clean install dependencies
print_message "Installing frontend dependencies..."
rm -rf node_modules package-lock.json
npm install || {
    print_error "Failed to install frontend dependencies"
    exit 1
}

# Build frontend with production optimization
print_message "Building frontend..."
npm run build || {
    print_error "Failed to build frontend"
    print_warning "Check the build logs for errors"
    exit 1
}

# Set proper permissions with security in mind
print_message "Setting permissions..."
find /opt/ClassServer -type f -exec chmod 644 {} \;
find /opt/ClassServer -type d -exec chmod 755 {} \;
chmod 750 /opt/ClassServer/venv
chmod 750 /opt/ClassServer/backend
chmod 750 /opt/ClassServer/scripts
chown -R www-data:www-data /opt/ClassServer || {
    print_error "Failed to set proper permissions"
    exit 1
}

# Start and enable backend service with proper checks
print_message "Starting backend service..."
systemctl daemon-reload || {
    print_error "Failed to reload systemd configuration"
    exit 1
}

systemctl enable classserver-backend || {
    print_error "Failed to enable backend service"
    exit 1
}

systemctl start classserver-backend || {
    print_error "Failed to start backend service"
    exit 1
}

# Create backup script with improved error handling and logging
print_message "Creating backup script..."
cat > /opt/ClassServer/scripts/backup.sh << 'EOF'
#!/bin/bash

# Exit on error
set -e

# Configuration
BACKUP_DIR="/opt/ClassServer/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DB_USER="classserver"
DB_NAME="classserver"
LOG_FILE="/var/log/classserver-backup.log"

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Error handling function
handle_error() {
    local error_message="$1"
    log_message "ERROR: $error_message"
    echo "Backup failed: $error_message" >&2
    exit 1
}

# Ensure backup directory exists and has correct permissions
mkdir -p "$BACKUP_DIR"/{daily,weekly,monthly} || handle_error "Failed to create backup directories"
chown www-data:www-data "$BACKUP_DIR" -R || handle_error "Failed to set backup directory permissions"
chmod 750 "$BACKUP_DIR" -R || handle_error "Failed to set backup directory permissions"

# Load database password from environment file
if [ ! -f "/opt/ClassServer/scripts/backup.env" ]; then
    handle_error "Backup environment file not found"
fi
source /opt/ClassServer/scripts/backup.env

# Perform database backup
log_message "Starting database backup"
export PGPASSWORD="$DB_PASSWORD"
pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_DIR/daily/db_$TIMESTAMP.sql" || handle_error "Database backup failed"
unset PGPASSWORD

# Backup uploads directory if exists
if [ -d "/opt/ClassServer/backend/uploads" ]; then
    log_message "Backing up uploads directory"
    tar -czf "$BACKUP_DIR/daily/uploads_$TIMESTAMP.tar.gz" /opt/ClassServer/backend/uploads || handle_error "Uploads backup failed"
fi

# Rotate backups
find "$BACKUP_DIR/daily" -type f -mtime +7 -delete
find "$BACKUP_DIR/weekly" -type f -mtime +30 -delete
find "$BACKUP_DIR/monthly" -type f -mtime +365 -delete

# Set proper permissions for backup files
chmod 640 "$BACKUP_DIR"/*/*.sql "$BACKUP_DIR"/*/*.tar.gz 2>/dev/null || true

log_message "Backup completed successfully"
EOF

# Create environment file for backup script
print_message "Creating backup environment file..."
cat > /opt/ClassServer/scripts/backup.env << EOF
DB_PASSWORD="$DB_PASSWORD"
EOF

# Set proper permissions for scripts and environment file
chmod 750 /opt/ClassServer/scripts/backup.sh
chmod 640 /opt/ClassServer/scripts/backup.env
chown -R www-data:www-data /opt/ClassServer/scripts
touch /var/log/classserver-backup.log
chown www-data:www-data /var/log/classserver-backup.log
chmod 640 /var/log/classserver-backup.log

# Add backup cron job for www-data user with error handling
print_message "Setting up backup cron job..."
(crontab -u www-data -l 2>/dev/null; echo "0 3 * * * /opt/ClassServer/scripts/backup.sh >> /var/log/classserver-backup.log 2>&1") | crontab -u www-data - || {
    print_error "Failed to set up backup cron job"
    exit 1
}

# Create log rotation configuration
cat > /etc/logrotate.d/classserver << EOF
/var/log/classserver-backup.log {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    create 640 www-data www-data
}
EOF

print_message "Installation completed successfully!"
print_message "Your server is now running at http://$SERVER_ADDRESS"
print_message "Important next steps:"
print_message "1. If using a local domain name, add this line to your /etc/hosts file:"
print_message "   $(hostname -I | awk '{print $1}') $SERVER_ADDRESS"
print_message "2. Verify the backend service: systemctl status classserver-backend"
print_message "3. Check the backup system: /opt/ClassServer/scripts/backup.sh"
print_message "4. Monitor logs: tail -f /var/log/classserver-backup.log"
print_warning "Keep your database password safe: $DB_PASSWORD" 