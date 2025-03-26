#!/bin/bash

# Create groups if they don't exist
sudo groupadd -g 1000 nodered 2>/dev/null || true
sudo groupadd -g 999 postgres 2>/dev/null || true
sudo groupadd -g 1883 mosquitto 2>/dev/null || true
sudo groupadd -g 472 grafana 2>/dev/null || true

# Create directories if they don't exist
mkdir -p influxdb-data postgres-data nodered-data mosquitto/data mosquitto/log grafana-data

# Set ownership and permissions for InfluxDB
sudo chown -R 1000:1000 influxdb-data
sudo chmod -R 775 influxdb-data

# Set ownership and permissions for PostgreSQL
sudo chown -R 999:999 postgres-data
sudo chmod -R 700 postgres-data

# Set ownership and permissions for Node-RED
sudo chown -R 1000:1000 nodered-data
sudo chmod -R 775 nodered-data

# Set ownership and permissions for Mosquitto
sudo chown -R 1883:1883 mosquitto/data
sudo chown -R 1883:1883 mosquitto/log
sudo chmod -R 775 mosquitto/data
sudo chmod -R 775 mosquitto/log

# Set ownership and permissions for Grafana
sudo chown -R 472:472 grafana-data
sudo chmod -R 755 grafana-data

# Ensure the current user can access all directories
sudo usermod -aG 1000,999,1883,472 $USER

echo "Permissions have been set up successfully!"
