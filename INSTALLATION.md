# ClassServer Installation Guide for Ubuntu LTS

This guide will help you install ClassServer on Ubuntu LTS (20.04 or 22.04). Just follow these simple steps.

## Quick Install

Copy and paste these commands into your terminal:

```bash
# Update system and install prerequisites
sudo apt update
sudo apt install -y git docker.io docker-compose

# Start and enable Docker
sudo systemctl enable --now docker

# Add your user to Docker group (needed to run Docker without sudo)
sudo usermod -aG docker $USER

# Clone the repository
git clone https://github.com/1ELER-24-25/ClassServer.git
cd ClassServer

# Set up environment file
cp .env.example .env

## Environment Configuration
# Edit the .env file to set required passwords and configuration:
nano .env

Required settings:
- `INFLUXDB_ADMIN_PASSWORD`: Set a secure password for InfluxDB
- `POSTGRES_PASSWORD`: Set a secure password for PostgreSQL
- `FLASK_SECRET_KEY`: Set a random string for Flask security

# Set up permissions and start services
chmod +x setup-permissions.sh
./setup-permissions.sh
docker-compose up -d
```

**Important**: After running these commands, log out and log back in for group changes to take effect.

## Verify Installation

Open these URLs in your browser:
- Web Interface: http://localhost:5000
- Node-RED: http://localhost:1880
- InfluxDB: http://localhost:8086
- Adminer: http://localhost:8080

## Troubleshooting

### Common Issues

1. **"Permission denied" errors**:
   ```bash
   # Run the permissions script again
   ./setup-permissions.sh
   ```

2. **Port already in use**:
   ```bash
   # Check which process is using the port (example for port 5000)
   sudo lsof -i :5000
   ```

3. **Docker service not running**:
   ```bash
   sudo systemctl start docker
   ```

4. **View container logs**:
   ```bash
   # View logs for all containers
   docker-compose logs

   # View logs for specific service (e.g., webapp)
   docker-compose logs webapp
   ```

### Need Help?

If you encounter any issues:
1. Check the container logs
2. Ensure all ports (5000, 1880, 8086, 8080) are available
3. Verify Docker is running
4. Open an issue on our GitHub repository

## Environment Configuration

After installation, edit the `.env` file to set your passwords and configuration:
```bash
nano .env
```

Required settings:
- `INFLUXDB_ADMIN_PASSWORD`: Set a secure password for InfluxDB
- `POSTGRES_PASSWORD`: Set a secure password for PostgreSQL
- `FLASK_SECRET_KEY`: Set a random string for Flask security

After changing environment variables, restart the services:
```bash
docker-compose down
docker-compose up -d
```

## Uninstall

To remove ClassServer:
```bash
# Stop and remove containers
docker-compose down

# Remove data directories
sudo rm -rf influxdb-data postgres-data nodered-data mosquitto
```


