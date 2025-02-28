#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Create backup directories
print_message "Creating backup directories..."
sudo mkdir -p /opt/ClassServer/backups/{database,config}
sudo mkdir -p /opt/ClassServer/scripts
sudo chmod 700 /opt/ClassServer/backups

# Create database environment file if it doesn't exist
print_message "Creating database environment file..."
if [ ! -f "/opt/ClassServer/config/database.env" ]; then
    sudo mkdir -p /opt/ClassServer/config
    cat > /opt/ClassServer/config/database.env << EOF
POSTGRES_USER=classserver
POSTGRES_PASSWORD=classserver
POSTGRES_DB=classserver
POSTGRES_HOST=localhost
EOF
fi

# Create backup script
print_message "Creating backup script..."
cat > /opt/ClassServer/scripts/backup.sh << 'EOF'
#!/bin/bash

# Set backup directory
BACKUP_DIR="/opt/ClassServer/backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)

# Database credentials
DB_USER="classserver"
DB_NAME="classserver"

# Backup database
print_message "Creating database backup..."
pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_DIR/database/db_backup_$DATE.sql"

# Backup configuration files
print_message "Creating configuration backup..."
tar -czf "$BACKUP_DIR/config/config_backup_$DATE.tar.gz" /opt/ClassServer/config/

# Remove backups older than 7 days
print_message "Cleaning up old backups..."
find "$BACKUP_DIR/database" -name "db_backup_*.sql" -mtime +7 -delete
find "$BACKUP_DIR/config" -name "config_backup_*.tar.gz" -mtime +7 -delete

print_message "Backup completed successfully!"
EOF

# Make backup script executable
sudo chmod +x /opt/ClassServer/scripts/backup.sh

# Create cron job for daily backups at 3 AM
print_message "Setting up daily backup cron job..."
(crontab -l 2>/dev/null || true; echo "0 3 * * * /opt/ClassServer/scripts/backup.sh") | crontab -

# Set backup directory permissions
print_message "Setting backup permissions..."
sudo chown -R postgres:postgres /opt/ClassServer/backups/database
sudo chown -R root:root /opt/ClassServer/backups/config
sudo chmod 700 /opt/ClassServer/backups/{database,config}

print_success "Backup setup completed successfully!" 