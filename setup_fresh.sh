#!/bin/bash

# Remove existing ClassServer directory if it exists
rm -rf ~/ClassServer

# Clone the repository from the correct URL
git clone https://github.com/1ELER-24-25/ClassServer.git ~/ClassServer

# Make all scripts executable
cd ~/ClassServer
chmod +x scripts/*.sh

echo "Repository has been reset and scripts are now executable!"
echo "You can now run: sudo ~/ClassServer/scripts/install.sh" 