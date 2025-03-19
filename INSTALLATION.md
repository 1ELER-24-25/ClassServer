# ClassServer Installation Guide for Ubuntu LTS

This guide will help you install ClassServer on Ubuntu LTS (20.04 or 22.04).

## Prerequisites

1. Check available ports:
```bash
# Verify required ports are free
sudo lsof -i :5000    # Flask web interface
sudo lsof -i :1880    # Node-RED
sudo lsof -i :8086    # InfluxDB
sudo lsof -i :8080    # Adminer
sudo lsof -i :1883    # MQTT
```

2. Ensure Docker is installed and running:
```bash
# Install Docker and Docker Compose
sudo apt update
sudo apt install -y git docker.io docker-compose

# Start and enable Docker
sudo systemctl status docker    # Check status
sudo systemctl start docker    # Start if needed
sudo systemctl enable docker   # Enable on boot

# Add your user to Docker group
sudo usermod -aG docker $USER
```

**Important**: Log out and log back in for group changes to take effect.

## Installation

1. Clone and prepare the repository:
```bash
git clone https://github.com/1ELER-24-25/ClassServer.git
cd ClassServer
```

2. Configure environment:
```bash
# Create and edit environment file
cp .env.example .env
nano .env

# Required settings in .env:
INFLUXDB_ADMIN_PASSWORD=your_secure_password
POSTGRES_PASSWORD=your_secure_password
FLASK_SECRET_KEY=your_random_string
```

3. Set up permissions and start services:
```bash
chmod +x setup-permissions.sh
./setup-permissions.sh
docker-compose up -d
```

## Verify Installation

1. Check container status:
```bash
# List running containers
docker-compose ps

# Check container logs
docker-compose logs         # All containers
docker-compose logs webapp  # Specific container
```

2. Open these URLs in your browser:
- Web Interface: http://localhost:5000
- Node-RED: http://localhost:1880
- InfluxDB: http://localhost:8086
- Adminer: http://localhost:8080

## Common Docker Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart specific service
docker-compose restart webapp

# View real-time logs
docker-compose logs -f

# Check container resource usage
docker stats

# Rebuild containers after changes
docker-compose up -d --build
```

## Troubleshooting

1. **"Permission denied" errors**:
```bash
./setup-permissions.sh
```

2. **Port conflicts**:
```bash
# Find process using a port
sudo lsof -i :5000
# Kill process if needed
sudo kill <PID>
```

3. **Container issues**:
```bash
# Check container status
docker-compose ps
# View detailed container info
docker inspect <container_name>
```

## Maintenance

### Update Services
```bash
# Pull latest images
docker-compose pull

# Rebuild and restart
docker-compose up -d --build
```

### Backup Data
```bash
# Stop services before backup
docker-compose down

# Backup data directories
tar -czf classserver-backup.tar.gz influxdb-data postgres-data nodered-data mosquitto
```

## Uninstall

```bash
# Stop and remove containers
docker-compose down

# Remove data directories
sudo rm -rf influxdb-data postgres-data nodered-data mosquitto
```

## InfluxDB Setup

The InfluxDB instance is automatically configured with:
- Organization: classroom
- Bucket: games
- Retention: 7 days
- Measurement: chess_moves

To verify the setup:
1. Visit http://localhost:8086
2. Login with credentials from .env
3. Check Data Explorer to see chess_moves measurement

Common InfluxDB CLI commands:
```bash
# Check bucket status
docker-compose exec influxdb influx bucket list

# View retention policies
docker-compose exec influxdb influx bucket list --org classroom

# Manual data exploration
docker-compose exec influxdb influx query \
    --org classroom \
    'from(bucket:"games") |> range(start: -1h)'
```

## Need Help?

If you encounter issues:
1. Check container logs using commands above
2. Verify all ports are available
3. Ensure Docker is running properly
4. Open an issue on our GitHub repository with logs and error details


