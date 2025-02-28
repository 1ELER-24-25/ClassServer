#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_message "Setting up PostgreSQL database for ClassServer..."

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    print_error "PostgreSQL is not installed. Please install it first with:"
    print_error "sudo apt update && sudo apt install -y postgresql postgresql-contrib"
    exit 1
fi

# Check if PostgreSQL is running
if ! systemctl is-active --quiet postgresql; then
    print_message "Starting PostgreSQL service..."
    sudo systemctl start postgresql
fi

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

# Update PostgreSQL to listen on all interfaces
print_message "Configuring PostgreSQL to listen on all interfaces..."
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

# Get network access configuration
print_message "Configuring network access..."
NETWORK_ACCESS=$(get_network_access)

# Add network access rules
for network in $NETWORK_ACCESS; do
    if ! sudo grep -q "^host    $DB_NAME    $DB_USER    $network    md5" /etc/postgresql/*/main/pg_hba.conf; then
        print_message "Adding access rule for network: $network"
        sudo bash -c "echo 'host    $DB_NAME    $DB_USER    $network    md5' >> /etc/postgresql/*/main/pg_hba.conf"
    fi
done

# Always ensure localhost access
if ! sudo grep -q "^host    $DB_NAME    $DB_USER    127.0.0.1/32    md5" /etc/postgresql/*/main/pg_hba.conf; then
    # Add entry for localhost connections
    sudo bash -c "echo 'host    $DB_NAME    $DB_USER    127.0.0.1/32    md5' >> /etc/postgresql/*/main/pg_hba.conf"
fi

if ! sudo grep -q "^local   $DB_NAME    $DB_USER    md5" /etc/postgresql/*/main/pg_hba.conf; then
    # Add entry for local connections
    sudo bash -c "echo 'local   $DB_NAME    $DB_USER    md5' >> /etc/postgresql/*/main/pg_hba.conf"
fi

# Restart PostgreSQL to apply changes
print_message "Restarting PostgreSQL service..."
sudo systemctl restart postgresql

# Verify connection
print_message "Verifying database connection..."
if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
    print_success "Database connection successful!"
else
    print_error "Failed to connect to the database. Please check your PostgreSQL configuration."
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

print_message "Database setup completed successfully!"
print_message "You can now run the add_mock_players.sh script to populate the database with mock data." 