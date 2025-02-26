# Detailed Installation Guide

This guide provides comprehensive instructions for setting up the ClassServer project for development.

## Prerequisites

### Software Requirements

#### Required
- **Node.js** (18 or later)
  ```bash
  # Using nvm (recommended)
  nvm install 18
  nvm use 18
  
  # Or download from nodejs.org
  ```

- **PostgreSQL** (14 or later)
  ```bash
  # Ubuntu
  sudo apt update
  sudo apt install postgresql postgresql-contrib
  
  # Windows
  # Download installer from postgresql.org
  
  # macOS using Homebrew
  brew install postgresql@14
  ```

- **Git**
  ```bash
  # Ubuntu
  sudo apt install git
  
  # Windows
  # Download from git-scm.com
  
  # macOS
  brew install git
  ```

#### Optional but Recommended
- **Visual Studio Code** with extensions:
  - ESLint
  - Prettier
  - Tailwind CSS IntelliSense
  - PostgreSQL

### Hardware Requirements (for Game Controllers)

- **ESP32 Development Board**
  - Recommended: ESP32-WROOM-32
  - Alternative: ESP32-DevKitC

- **RFID Reader**
  - MFRC522 RFID module
  - Compatible RFID cards/tags (13.56 MHz)

- **Additional Hardware**
  - Micro USB cable
  - Breadboard and jumper wires
  - 3.3V power supply

### Development Environment Setup

1. **PostgreSQL Setup**
   ```bash
   # Start PostgreSQL service
   # Ubuntu
   sudo systemctl start postgresql
   sudo systemctl enable postgresql
   
   # Windows
   # PostgreSQL service starts automatically
   
   # macOS
   brew services start postgresql@14
   
   # Create database user
   sudo -u postgres createuser --interactive
   # Enter name of role to add: classserver
   # Shall the new role be a superuser? y
   
   # Set password for new user
   sudo -u postgres psql
   postgres=# \password classserver
   # Enter new password
   ```

2. **Node.js Configuration**
   ```bash
   # Install global packages
   npm install -g npm@latest
   npm install -g nodemon
   npm install -g sequelize-cli
   
   # Verify installations
   node --version
   npm --version
   nodemon --version
   sequelize --version
   ```

3. **ESP-IDF Setup (for Hardware Development)**
   ```bash
   # Ubuntu
   sudo apt-get install git wget flex bison gperf python3 python3-pip python3-setuptools cmake ninja-build ccache libfragmentation-dev libssl-dev libusb-1.0-0
   
   # Clone ESP-IDF
   mkdir -p ~/esp
   cd ~/esp
   git clone --recursive https://github.com/espressif/esp-idf.git
   
   # Install ESP-IDF
   cd ~/esp/esp-idf
   ./install.sh
   . ./export.sh
   ```

## Project Setup

1. **Clone and Configure**
   ```bash
   # Clone repository
   git clone https://github.com/yourusername/ClassServer.git
   cd ClassServer
   
   # Copy environment files
   cp .env.example .env
   ```

2. **Environment Configuration**
   Edit `.env` file with your settings:
   ```ini
   # Required settings
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=classserver
   DB_USER=your_username
   DB_PASSWORD=your_password
   
   # Optional settings
   NODE_ENV=development
   PORT=3000
   ```

3. **Database Setup**
   ```bash
   # Create database
   createdb classserver
   
   # Run migrations
   npm run migrate --workspace=backend
   
   # (Optional) Run seeds
   npm run seed --workspace=backend
   ```

4. **Install Dependencies**
   ```bash
   # Install all dependencies
   npm install
   
   # Or install workspace specific
   npm install --workspace=frontend
   npm install --workspace=backend
   ```

## Running the Application

1. **Development Mode**
   ```bash
   # Start both frontend and backend
   npm run start
   
   # Or start separately
   npm run start:frontend  # Runs on http://localhost:5173
   npm run start:backend   # Runs on http://localhost:3000
   ```

2. **Testing**
   ```bash
   # Run all tests
   npm test
   
   # Run specific workspace tests
   npm test --workspace=frontend
   npm test --workspace=backend
   ```

## Common Issues and Solutions

### Database Connection Issues
- Ensure PostgreSQL service is running
- Verify database credentials in `.env`
- Check if database exists: `psql -l | grep classserver`

### Node.js Errors
- Clear npm cache: `npm cache clean --force`
- Delete node_modules: `rm -rf node_modules`
- Reinstall dependencies: `npm install`

### ESP32 Upload Issues
- Check USB connection
- Verify correct port in ESP-IDF configuration
- Hold BOOT button while uploading

## Additional Resources

- [Node.js Documentation](https://nodejs.org/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [ESP32 Getting Started Guide](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/)
- [Sequelize Documentation](https://sequelize.org/) 