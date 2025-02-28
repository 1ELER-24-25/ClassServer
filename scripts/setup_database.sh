#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Setting up PostgreSQL database for ClassServer..."

# Function to ensure PostgreSQL is running
ensure_postgresql_running() {
    print_message "Checking PostgreSQL service status..."
    if ! systemctl is-active --quiet postgresql; then
        print_message "PostgreSQL is not running. Attempting to start..."
        sudo systemctl start postgresql
        # Wait for PostgreSQL to start
        for i in {1..30}; do
            if sudo -u postgres psql -c '\l' >/dev/null 2>&1; then
                print_success "PostgreSQL started successfully"
                return 0
            fi
            sleep 1
        done
        print_error "Failed to start PostgreSQL. Please check the logs with: sudo journalctl -u postgresql"
        exit 1
    fi
}

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    print_error "PostgreSQL is not installed. Please install it first with:"
    print_error "sudo apt update && sudo apt install -y postgresql postgresql-contrib"
    exit 1
fi

# Ensure PostgreSQL is running before proceeding
ensure_postgresql_running

# Set database credentials
DB_NAME="classserver"
DB_USER="classserver"
DB_PASSWORD=${DB_PASSWORD:-"classserver"}

# Check if PostgreSQL user exists and create if needed
print_message "Checking PostgreSQL user..."
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    print_message "Creating PostgreSQL user '$DB_USER'..."
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
fi

# Check if database exists and create if needed
print_message "Checking PostgreSQL database..."
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
    print_message "Creating PostgreSQL database '$DB_NAME'..."
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
fi

# Grant privileges
print_message "Granting privileges..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# Update PostgreSQL authentication configuration
print_message "Updating PostgreSQL authentication configuration..."

# Backup existing pg_hba.conf
PG_HBA_CONF=$(find /etc/postgresql -name "pg_hba.conf")
if [ -f "$PG_HBA_CONF" ]; then
    print_message "Backing up existing pg_hba.conf..."
    sudo cp "$PG_HBA_CONF" "${PG_HBA_CONF}.bak"
fi

# Update PostgreSQL to listen on all interfaces
print_message "Configuring PostgreSQL to listen on all interfaces..."
PG_CONF=$(find /etc/postgresql -name "postgresql.conf")
if [ -f "$PG_CONF" ]; then
    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
fi

# Get network access configuration
print_message "Configuring network access..."
NETWORK_ACCESS=$(get_network_access)

# Add network access rules
for network in $NETWORK_ACCESS; do
    if ! sudo grep -q "^host    $DB_NAME    $DB_USER    $network    md5" "$PG_HBA_CONF"; then
        print_message "Adding access rule for network: $network"
        sudo bash -c "echo 'host    $DB_NAME    $DB_USER    $network    md5' >> $PG_HBA_CONF"
    fi
done

# Always ensure localhost access
if ! sudo grep -q "^host    $DB_NAME    $DB_USER    127.0.0.1/32    md5" "$PG_HBA_CONF"; then
    print_message "Adding localhost access rule"
    sudo bash -c "echo 'host    $DB_NAME    $DB_USER    127.0.0.1/32    md5' >> $PG_HBA_CONF"
fi

if ! sudo grep -q "^local   $DB_NAME    $DB_USER    md5" "$PG_HBA_CONF"; then
    print_message "Adding local socket access rule"
    sudo bash -c "echo 'local   $DB_NAME    $DB_USER    md5' >> $PG_HBA_CONF"
fi

# Restart PostgreSQL to apply changes
print_message "Restarting PostgreSQL service..."
sudo systemctl restart postgresql

# Wait for PostgreSQL to restart
print_message "Waiting for PostgreSQL to restart..."
sleep 5
ensure_postgresql_running

# Verify connection
print_message "Verifying database connection..."
if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
    print_success "Database connection successful!"
else
    print_error "Failed to connect to the database. Please check your PostgreSQL configuration."
    print_message "You can check PostgreSQL logs with: sudo journalctl -u postgresql"
    print_message "You can also try manually restarting PostgreSQL with: sudo systemctl restart postgresql"
    exit 1
fi

# Create backend directory structure if it doesn't exist
print_message "Creating backend directory structure..."
BACKEND_DIR="/opt/ClassServer/backend"
sudo mkdir -p "$BACKEND_DIR/src/config"
sudo chown -R $(whoami) "$BACKEND_DIR"

# Create database configuration file
print_message "Creating database configuration file..."
cat > "$BACKEND_DIR/src/config/database.js" << EOF
module.exports = {
  database: process.env.DB_NAME || '$DB_NAME',
  username: process.env.DB_USER || '$DB_USER',
  password: process.env.DB_PASSWORD || '$DB_PASSWORD',
  host: process.env.DB_HOST || 'localhost',
  dialect: 'postgres',
  logging: false
};
EOF

print_success "Database setup completed successfully!"
print_message "You can now run the add_mock_players.sh script to populate the database with mock data." 