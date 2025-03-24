# ESP32 Analog Sensor Example

## Setup Instructions

1. Copy the secrets template to create your configuration:
   ```bash
   cp secrets.h.example secrets.h
   ```

2. Edit `secrets.h` with your settings:
   - WiFi network name and password
   - MQTT broker IP address
   - Device ID

3. Adjust sensor settings in `AnalogSensorExample.ino`:
   - `SENSOR_PIN`: GPIO pin your sensor is connected to
   - `READING_INTERVAL`: How often to take readings
   - `MQTT_TOPIC`: Where to publish sensor data

4. Upload the code to your ESP32

## Files
- `AnalogSensorExample.ino`: Main program
- `secrets.h`: Your private configuration (not in git)
- `secrets.h.example`: Template for secrets.h
- `.gitignore`: Prevents secrets from being committed

## Security Notes
- Never commit `secrets.h` to git
- Keep your WiFi and MQTT credentials private
- Use unique device IDs for each sensor