/*
 * ESP32 Analog Sensor Example
 * 
 * This template demonstrates how to:
 * 1. Connect an ESP32 to WiFi
 * 2. Read an analog sensor
 * 3. Send data to an MQTT broker
 * 
 * Created for 1ELER classroom project
 * 
 * SETUP INSTRUCTIONS:
 * 1. Copy secrets.h.example to secrets.h
 * 2. Update secrets.h with your WiFi and MQTT settings
 * 3. Update the sensor settings below as needed
 */

#include <WiFi.h>        // Built-in ESP32 WiFi library
#include <PubSubClient.h> // MQTT library - install via Arduino Library Manager
#include "secrets.h"     // Sensitive configuration (not in git)
#include <math.h>        // For sin() function

//////////////////////////////////////////////////////////////////
// SENSOR CONFIGURATION - Adjust these for your sensor
//////////////////////////////////////////////////////////////////

// Sensor Settings
const int SENSOR_PIN = 34;                    // GPIO pin connected to sensor (ADC1_CH6)
const long READING_INTERVAL = 5000;           // How often to read sensor (in milliseconds)

// MQTT Topic
const char* MQTT_TOPIC = "sensors/analog/sensor1"; // MQTT topic to publish to

// Advanced Settings
const int SERIAL_BAUD = 115200;               // Serial monitor baud rate
const int JSON_BUFFER_SIZE = 100;             // Size of buffer for JSON messages

//////////////////////////////////////////////////////////////////
// Global Variables - Don't change unless you know what you're doing
//////////////////////////////////////////////////////////////////

WiFiClient espClient;                         // WiFi client object
PubSubClient mqttClient(espClient);           // MQTT client object
unsigned long lastReadingTime = 0;            // Tracks last sensor reading time

// New variables for simulation
bool simulationMode = false;
float simulationAngle = 0.0;  // For sine wave generation
//const float TWO_PI = 6.28318530718;
const float SIMULATION_AMPLITUDE = 2000.0;  // Amplitude of sine wave
const float SIMULATION_OFFSET = 2047.0;     // Center point of sine wave
const float SIMULATION_NOISE = 100.0;       // Random noise amplitude

//////////////////////////////////////////////////////////////////
// Setup Functions
//////////////////////////////////////////////////////////////////

void setupWiFi() {
  Serial.println("\n=== WiFi Setup ===");
  Serial.printf("Connecting to %s ", WIFI_SSID);
  
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  // Wait for connection
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi Connected!");
  Serial.printf("IP address: %s\n", WiFi.localIP().toString().c_str());
}

void setupMQTT() {
  Serial.println("\n=== MQTT Setup ===");
  mqttClient.setServer(MQTT_SERVER, MQTT_PORT);
  Serial.printf("MQTT Broker: %s:%d\n", MQTT_SERVER, MQTT_PORT);
  Serial.printf("MQTT Topic: %s\n", MQTT_TOPIC);
}

void setupSensor() {
  Serial.println("\n=== Sensor Setup ===");
  pinMode(SENSOR_PIN, INPUT);
  Serial.printf("Sensor PIN: %d\n", SENSOR_PIN);
  Serial.printf("Reading Interval: %ld ms\n", READING_INTERVAL);
}

//////////////////////////////////////////////////////////////////
// Simulation Functions
//////////////////////////////////////////////////////////////////

int generateSimulatedReading() {
  // Generate a sine wave with some random noise
  float sineValue = sin(simulationAngle);
  float noise = (random(1000) / 1000.0 - 0.5) * SIMULATION_NOISE;
  
  // Calculate final value
  int simulatedValue = (int)(SIMULATION_OFFSET + sineValue * SIMULATION_AMPLITUDE + noise);
  
  // Ensure value stays within ADC range (0-4095)
  simulatedValue = constrain(simulatedValue, 0, 4095);
  
  // Increment angle for next reading (adjust speed by changing the increment)
  simulationAngle += 0.1;
  if (simulationAngle >= TWO_PI) {
    simulationAngle -= TWO_PI;
  }
  
  return simulatedValue;
}

void checkSerialCommand() {
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    
    if (command == "GEN") {
      simulationMode = true;
      Serial.println("Switching to simulation mode - generating fake measurements");
    } else if (command == "REAL") {
      simulationMode = false;
      Serial.println("Switching to real sensor mode");
    }
  }
}

//////////////////////////////////////////////////////////////////
// MQTT Functions
//////////////////////////////////////////////////////////////////

void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("Attempting MQTT connection...");
    
    if (mqttClient.connect(DEVICE_ID)) {
      Serial.println("connected");
    } else {
      Serial.printf("failed, rc=%d\n", mqttClient.state());
      Serial.println("Retrying in 5 seconds...");
      delay(5000);
    }
  }
}

void publishSensorData(int sensorValue, unsigned long timestamp) {
  // Create JSON payload
  char payload[JSON_BUFFER_SIZE];
  snprintf(payload, sizeof(payload), 
           "{\"device_id\":\"%s\",\"value\":%d,\"timestamp\":%lu}", 
           DEVICE_ID, sensorValue, timestamp);
  
  // Publish to MQTT
  mqttClient.publish(MQTT_TOPIC, payload);
  
  // Debug output
  Serial.println("\n=== Publishing Data ===");
  Serial.printf("Topic: %s\n", MQTT_TOPIC);
  Serial.printf("Payload: %s\n", payload);
}

//////////////////////////////////////////////////////////////////
// Main Arduino Functions
//////////////////////////////////////////////////////////////////

void setup() {
  // Initialize serial communication
  Serial.begin(SERIAL_BAUD);
  Serial.println("\nESP32 Analog Sensor Example Starting...");
  Serial.println("Type 'GEN' to start simulation mode");
  Serial.println("Type 'REAL' to use real sensor");
  
  // Setup components
  setupSensor();
  setupWiFi();
  setupMQTT();
  
  // Initialize random seed for simulation
  randomSeed(analogRead(SENSOR_PIN));
}

void loop() {
  // Check for serial commands
  checkSerialCommand();
  
  // Ensure MQTT connection
  if (!mqttClient.connected()) {
    reconnectMQTT();
  }
  mqttClient.loop();

  // Check if it's time to take a reading
  unsigned long currentTime = millis();
  if (currentTime - lastReadingTime >= READING_INTERVAL) {
    lastReadingTime = currentTime;
    
    // Get sensor value (real or simulated)
    int sensorValue;
    if (simulationMode) {
      sensorValue = generateSimulatedReading();
      Serial.printf("Simulated value: %d\n", sensorValue);
    } else {
      sensorValue = analogRead(SENSOR_PIN);
    }
    
    // Publish the reading
    publishSensorData(sensorValue, currentTime);
  }
}
