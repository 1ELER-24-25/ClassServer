/*
 * ESP32 RFID Reader
 * 
 * This program reads RFID cards and communicates with the ClassServer via MQTT.
 * It sends the card UID and receives user information in response.
 * 
 * Hardware:
 * - ESP32 DevKit
 * - MFRC522 RFID Reader
 * 
 * Connections:
 * MFRC522 | ESP32
 * ---------|-------
 * SDA(SS)  | 5
 * SCK      | 18
 * MOSI     | 23
 * MISO     | 19
 * GND      | GND
 * RST      | 21
 * 3.3V     | 3.3V
 */

#include <WiFi.h>
#include <PubSubClient.h>
#include <MFRC522.h>
#include <SPI.h>
#include "secrets.h"

// RFID pins
#define SS_PIN    5
#define RST_PIN   22

// MQTT Topics
const char* MQTT_TOPIC_SEND = "bruker/rfid";
const char* MQTT_TOPIC_RECEIVE = "bruker/navn";

// Device identification (using ESP32's unique MAC address)
String deviceId;

// Objects
MFRC522 rfid(SS_PIN, RST_PIN);
WiFiClient espClient;
PubSubClient mqttClient(espClient);

// Variables
String lastCardRead = "";
unsigned long lastCardReadTime = 0;
const unsigned long CARD_READ_DELAY = 2000; // Delay between reads (ms)

void setupWiFi() {
  Serial.println("\nConnecting to WiFi...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("\nWiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
  
  // Generate unique device ID from MAC address
  deviceId = WiFi.macAddress();
  deviceId.replace(":", ""); // Remove colons
  Serial.println("Device ID: " + deviceId);
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  // Convert payload to string
  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';
  
  // Check if this message is for us (contains our device ID)
  String msg = String(message);
  if (msg.startsWith(deviceId + ":")) {
    // Extract the actual message (after deviceId:)
    String userName = msg.substring(deviceId.length() + 1);
    Serial.println("Received user: " + userName);
    
    // Here you could add code to display the username on an LCD/OLED
    // or indicate with LEDs if a user was found
  }
}

void setupMQTT() {
  mqttClient.setServer(MQTT_SERVER, MQTT_PORT);
  mqttClient.setCallback(mqttCallback);
}

void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (mqttClient.connect(deviceId.c_str())) {
      Serial.println("connected");
      // Subscribe to receive responses
      mqttClient.subscribe(MQTT_TOPIC_RECEIVE);
    } else {
      Serial.print("failed, rc=");
      Serial.print(mqttClient.state());
      Serial.println(" retrying in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  while (!Serial);
  
  // Initialize SPI and RFID reader
  SPI.begin();
  rfid.PCD_Init();
  
  setupWiFi();
  setupMQTT();
  
  Serial.println("Ready to read RFID cards!");
}

String getCardUID() {
  String uid = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    uid += (rfid.uid.uidByte[i] < 0x10 ? "0" : "");
    uid += String(rfid.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();
  return uid;
}

void publishCardUID(String uid) {
  // Create message with device ID and UID
  String message = deviceId + ":" + uid;
  mqttClient.publish(MQTT_TOPIC_SEND, message.c_str());
  Serial.println("Published: " + message);
}

void loop() {
  if (!mqttClient.connected()) {
    reconnectMQTT();
  }
  mqttClient.loop();

  // Check if there's a new card present
  if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    unsigned long currentTime = millis();
    
    // Check if enough time has passed since last read
    if (currentTime - lastCardReadTime >= CARD_READ_DELAY) {
      String uid = getCardUID();
      
      // Only publish if it's a different card or enough time has passed
      if (uid != lastCardRead || (currentTime - lastCardReadTime >= 5000)) {
        publishCardUID(uid);
        lastCardRead = uid;
        lastCardReadTime = currentTime;
      }
    }
    
    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();
  }
}