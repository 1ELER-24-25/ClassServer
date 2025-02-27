#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Create backup directories
print_message "Creating backup directories..."
mkdir -p /opt/ClassServer/backups/{database,config}
chmod 700 /opt/ClassServer/backups

# Create backup script
print_message "Creating backup script..."
cat > /opt/ClassServer/scripts/backup.sh << 'EOF'
#!/bin/bash

# Load database configuration
source /opt/ClassServer/config/database.env

# Set backup directory
BACKUP_DIR="/opt/ClassServer/backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)

# Backup database
pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > "$BACKUP_DIR/database/db_backup_$DATE.sql"

# Backup configuration files
tar -czf "$BACKUP_DIR/config/config_backup_$DATE.tar.gz" /opt/ClassServer/config/

# Remove backups older than 7 days
find "$BACKUP_DIR/database" -name "db_backup_*.sql" -mtime +7 -delete
find "$BACKUP_DIR/config" -name "config_backup_*.tar.gz" -mtime +7 -delete
EOF

# Make backup script executable
chmod +x /opt/ClassServer/scripts/backup.sh

# Create cron job for daily backups at 3 AM
print_message "Setting up daily backup cron job..."
(crontab -l 2>/dev/null || true; echo "0 3 * * * /opt/ClassServer/scripts/backup.sh") | crontab -

# Set backup directory permissions
print_message "Setting backup permissions..."
chown -R postgres:postgres /opt/ClassServer/backups/database
chown -R root:root /opt/ClassServer/backups/config
chmod 700 /opt/ClassServer/backups/{database,config}

print_message "Backup setup completed successfully!" 