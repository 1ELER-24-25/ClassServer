#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Get server address
SERVER_ADDRESS=$(get_server_address)

# Create Nginx security configuration
print_message "Creating Nginx security configuration..."
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
    location /api/ {
        proxy_pass http://localhost:8000/;
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

print_message "Nginx setup completed successfully!" 