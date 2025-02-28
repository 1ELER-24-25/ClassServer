#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_message() {
    echo -e "${GREEN}[Setup] ${NC}$1"
}

print_warning() {
    echo -e "${YELLOW}[Warning] ${NC}$1"
}

print_error() {
    echo -e "${RED}[Error] ${NC}$1"
}

print_success() {
    echo -e "${BLUE}[Success] ${NC}$1"
}

# Export print functions
export -f print_message
export -f print_warning
export -f print_error
export -f print_success

# Validate IP address
validate_ip() {
    if echo "$1" | grep -qP '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$'; then
        local IFS='.'
        local -a ip=($1)
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        return $?
    fi
    return 1
}

# Validate domain name format (relaxed for local use)
validate_domain() {
    if ! echo "$1" | grep -qP '^[a-zA-Z0-9.-]+\.[a-zA-Z0-9-]{2,}$|^[a-zA-Z0-9-]+$'; then
        return 1
    fi
    return 0
}

# Get and validate server address
get_server_address() {
    while true; do
        read -p "Enter server address (IP or local domain, e.g., 192.168.1.100 or local.classserver): " SERVER_ADDRESS
        if ! validate_ip "$SERVER_ADDRESS" && ! validate_domain "$SERVER_ADDRESS"; then
            print_error "Invalid address format. Use an IP (e.g., 192.168.1.100) or local domain (e.g., local.classserver)"
            continue
        fi
        echo "$SERVER_ADDRESS"
        break
    done
}

# Get and validate database password
get_db_password() {
    while true; do
        read -s -p "Enter PostgreSQL password for classserver user: " DB_PASSWORD
        echo
        if [ ${#DB_PASSWORD} -lt 8 ]; then
            print_error "Password must be at least 8 characters long"
            continue
        fi
        echo "$DB_PASSWORD"
        break
    done
}

# Create a backup of existing installation
backup_existing_installation() {
    if [ -d "/opt/ClassServer" ]; then
        BACKUP_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        print_warning "Existing ClassServer installation found. Creating backup..."
        tar -czf "/opt/classserver_backup_${BACKUP_TIMESTAMP}.tar.gz" /opt/ClassServer
    fi
}

# Set proper permissions for files and directories
set_permissions() {
    find /opt/ClassServer -type f -exec chmod 644 {} \;
    find /opt/ClassServer -type d -exec chmod 755 {} \;
    chmod 750 /opt/ClassServer/venv
    chmod 750 /opt/ClassServer/backend
    chmod 750 /opt/ClassServer/scripts
    chown -R www-data:www-data /opt/ClassServer
}

# Get network access configuration
get_network_access() {
    while true; do
        echo "Select network access configuration for PostgreSQL:"
        echo "1) Allow from all networks (0.0.0.0/0) - Less secure, most flexible"
        echo "2) Allow from common private networks (192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12) - Good for most home/office setups"
        echo "3) Allow from specific network (you'll be prompted for network address) - Most secure"
        read -p "Enter choice [1-3]: " network_choice

        case $network_choice in
            1)
                echo "0.0.0.0/0"
                break
                ;;
            2)
                echo "192.168.0.0/16 10.0.0.0/8 172.16.0.0/12"
                break
                ;;
            3)
                read -p "Enter network address (e.g., 192.168.1.0/24): " custom_network
                if echo "$custom_network" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$'; then
                    echo "$custom_network"
                    break
                else
                    print_error "Invalid network address format. Please use CIDR notation (e.g., 192.168.1.0/24)"
                fi
                ;;
            *)
                print_error "Invalid choice. Please enter 1, 2, or 3"
                ;;
        esac
    done
}

# Export variables
export -f validate_ip
export -f validate_domain
export -f get_server_address
export -f get_db_password
export -f backup_existing_installation
export -f set_permissions
export -f get_network_access 