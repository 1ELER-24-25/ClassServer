#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print banner
echo -e "${GREEN}"
echo "================================================="
echo "          ClassServer Installation Script          "
echo "================================================="
echo -e "${NC}"

# Get server address once and export it for all scripts
echo -e "\n${YELLOW}Setting up server configuration...${NC}"
export SERVER_ADDRESS=$(get_server_address)
echo -e "Using server address: ${GREEN}${SERVER_ADDRESS}${NC}\n"

# Function to run a setup script and handle errors
run_setup() {
    local script=$1
    local description=$2
    
    echo -e "\n${YELLOW}Starting $description...${NC}"
    if ! bash "$SCRIPT_DIR/$script"; then
        echo -e "${RED}Failed to complete $description${NC}"
        exit 1
    fi
    echo -e "${GREEN}$description completed successfully${NC}"
}

# Backup existing installation if present
backup_existing_installation

# Run setup scripts in sequence
run_setup "setup_system.sh" "system setup"
run_setup "setup_database.sh" "database setup"
run_setup "setup_backend.sh" "backend setup"
run_setup "setup_frontend.sh" "frontend setup"
run_setup "setup_nginx.sh" "web server setup"
run_setup "setup_backup.sh" "backup configuration"
run_setup "setup_admin_complete.sh" "admin panel setup"

echo -e "\n${GREEN}================================================="
echo "ClassServer installation completed successfully!"
echo "=================================================${NC}"

# Print server address (using the already captured value)
echo -e "\nYou can now access ClassServer at: ${GREEN}http://${SERVER_ADDRESS}${NC}"
echo -e "API endpoint is available at: ${GREEN}http://${SERVER_ADDRESS}/api${NC}"
echo -e "Admin panel is available at: ${GREEN}http://${SERVER_ADDRESS}/admin${NC}"
echo -e "Admin login: ${YELLOW}admin@classserver.com${NC} / ${YELLOW}classserver${NC}"

# Print monitoring instructions
echo -e "\nTo monitor the services:"
echo -e "- Backend logs: ${YELLOW}journalctl -u classserver-backend -f${NC}"
echo -e "- Nginx logs: ${YELLOW}tail -f /var/log/nginx/access.log${NC}"
echo -e "- Database logs: ${YELLOW}tail -f /var/log/postgresql/postgresql-*.log${NC}" 