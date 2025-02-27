#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Get database password
DB_PASSWORD=$(get_db_password)

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

# Save database configuration
mkdir -p /opt/ClassServer/config
cat > /opt/ClassServer/config/database.env << EOF
DB_PASSWORD="$DB_PASSWORD"
DB_USER="classserver"
DB_NAME="classserver"
DB_HOST="localhost"
EOF

chmod 600 /opt/ClassServer/config/database.env
chown www-data:www-data /opt/ClassServer/config/database.env

print_message "Database setup completed successfully!" 