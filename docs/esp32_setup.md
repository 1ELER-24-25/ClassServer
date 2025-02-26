# ESP32 Setup and Communication Guide

This guide explains how to set up and program your ESP32 for communicating with the ClassServer using the Arduino IDE.

## Prerequisites

1. **Hardware Requirements**:
   - ESP32 Development Board
   - MFRC522 RFID Module
   - RFID Cards/Tags (13.56 MHz)
   - Micro USB Cable
   - Breadboard and jumper wires

2. **Software Requirements**:
   - Arduino IDE (2.0 or later)
   - ESP32 Board Package
   - Required Libraries:
     - `MFRC522` (for RFID)
     - `ArduinoJson` (for JSON parsing)
     - `WiFi`
     - `HTTPClient`

## Arduino IDE Setup

1. **Install ESP32 Board Package**:
   - Open Arduino IDE
   - Go to File → Preferences
   - Add to Additional Board Manager URLs:
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Go to Tools → Board → Boards Manager
   - Search for "esp32" and install "ESP32 by Espressif Systems"

2. **Install Required Libraries**:
   - Go to Tools → Manage Libraries
   - Install the following:
     - "MFRC522" by GithubCommunity
     - "ArduinoJson" by Benoit Blanchon
     - "WiFi" (built-in)
     - "HTTPClient" (built-in)

3. **Important: MFRC522 Library Fix for ESP32**:
   The MFRC522 library requires a manual fix to work properly with ESP32:
   
   a. Locate `MFRC522Extended.cpp` in your Arduino libraries folder:
      - Windows: `Documents\Arduino\libraries\MFRC522\src`
      - macOS: `~/Documents/Arduino/libraries/MFRC522/src`
      - Linux: `~/Arduino/libraries/MFRC522/src`
   
   b. Edit `MFRC522Extended.cpp`:
      - Find line 824: Change `if (backData && (backLen > 0))` to `if (backData && (*backLen > 0))`
      - Find line 847: Change `if (backData && (backLen > 0))` to `if (backData && (*backLen > 0))`
   
   c. Save the file and restart Arduino IDE

   > ⚠️ **Note**: This fix is required to prevent compilation errors when using the MFRC522 library with ESP32. Without this fix, you may encounter pointer-related errors.

## Hardware Connection

### MFRC522 RFID Module to ESP32:
```
MFRC522 Pin  |  ESP32 Pin
-------------|------------
SDA (SS)     |  GPIO 5
SCK          |  GPIO 18
MOSI         |  GPIO 23
MISO         |  GPIO 19
GND          |  GND
RST          |  GPIO 22
3.3V         |  3.3V
```

## Example Code

### 1. Basic Setup and WiFi Connection

```cpp
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <MFRC522.h>
#include <SPI.h>

// Network configuration
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* serverUrl = "http://your-server:3000/api";

// RFID configuration
#define SS_PIN  5  // SDA pin
#define RST_PIN 22
MFRC522 rfid(SS_PIN, RST_PIN);

void setup() {
  Serial.begin(115200);
  
  // Initialize WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected to WiFi");
  
  // Initialize RFID
  SPI.begin();
  rfid.PCD_Init();
}
```

### 2. RFID User Authentication

```cpp
// Function to get user info from RFID
bool getUserFromRFID(String uid, JsonDocument& userData) {
  if (WiFi.status() != WL_CONNECTED) return false;

  HTTPClient http;
  http.begin(String(serverUrl) + "/users/rfid/" + uid);
  
  int httpCode = http.GET();
  if (httpCode == HTTP_CODE_OK) {
    String payload = http.getString();
    DeserializationError error = deserializeJson(userData, payload);
    http.end();
    return !error;
  }
  
  http.end();
  return false;
}

// Function to read RFID card
String readRFIDCard() {
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial())
    return "";

  String uid = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    uid += String(rfid.uid.uidByte[i], HEX);
  }
  
  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();
  
  return uid;
}
```

### 3. Game Management

```cpp
// Start a new game
bool startGame(int gameType, String player1Uid, String player2Uid, String& matchId) {
  if (WiFi.status() != WL_CONNECTED) return false;

  StaticJsonDocument<200> doc;
  doc["game_type"] = gameType; // 1 for chess, 2 for foosball
  doc["player1_uid"] = player1Uid;
  doc["player2_uid"] = player2Uid;

  String jsonString;
  serializeJson(doc, jsonString);

  HTTPClient http;
  http.begin(String(serverUrl) + "/matches/start");
  http.addHeader("Content-Type", "application/json");
  
  int httpCode = http.POST(jsonString);
  if (httpCode == HTTP_CODE_OK) {
    StaticJsonDocument<200> response;
    deserializeJson(response, http.getString());
    matchId = response["match_id"].as<String>();
    http.end();
    return true;
  }
  
  http.end();
  return false;
}

// Update foosball score
bool updateFoosballScore(String matchId, int player1Score, int player2Score) {
  if (WiFi.status() != WL_CONNECTED) return false;

  StaticJsonDocument<200> doc;
  doc["player1_score"] = player1Score;
  doc["player2_score"] = player2Score;

  String jsonString;
  serializeJson(doc, jsonString);

  HTTPClient http;
  http.begin(String(serverUrl) + "/matches/" + matchId + "/score");
  http.addHeader("Content-Type", "application/json");
  
  int httpCode = http.POST(jsonString);
  http.end();
  return httpCode == HTTP_CODE_OK;
}

// Submit chess move
bool submitChessMove(String matchId, String move) {
  if (WiFi.status() != WL_CONNECTED) return false;

  StaticJsonDocument<200> doc;
  doc["move"] = move;

  String jsonString;
  serializeJson(doc, jsonString);

  HTTPClient http;
  http.begin(String(serverUrl) + "/matches/" + matchId + "/move");
  http.addHeader("Content-Type", "application/json");
  
  int httpCode = http.POST(jsonString);
  http.end();
  return httpCode == HTTP_CODE_OK;
}

// End game
bool endGame(String matchId, int winner) {
  if (WiFi.status() != WL_CONNECTED) return false;

  StaticJsonDocument<200> doc;
  doc["winner"] = winner; // 1 for player1, 2 for player2, 0 for draw

  String jsonString;
  serializeJson(doc, jsonString);

  HTTPClient http;
  http.begin(String(serverUrl) + "/matches/" + matchId + "/end");
  http.addHeader("Content-Type", "application/json");
  
  int httpCode = http.POST(jsonString);
  http.end();
  return httpCode == HTTP_CODE_OK;
}
```

### 4. Complete Example for Foosball Game

```cpp
String currentMatchId = "";
int player1Score = 0;
int player2Score = 0;

void loop() {
  // No active game - wait for player 1
  if (currentMatchId == "") {
    String uid = readRFIDCard();
    if (uid != "") {
      StaticJsonDocument<500> userData;
      if (getUserFromRFID(uid, userData)) {
        Serial.println("Player 1: " + userData["username"].as<String>());
        // Wait for player 2
        delay(5000);
        String uid2 = readRFIDCard();
        if (uid2 != "") {
          StaticJsonDocument<500> userData2;
          if (getUserFromRFID(uid2, userData2)) {
            Serial.println("Player 2: " + userData2["username"].as<String>());
            // Start game
            if (startGame(2, uid, uid2, currentMatchId)) {
              Serial.println("Game started!");
            }
          }
        }
      }
    }
  }
  // Active game - monitor score buttons
  else {
    // Example: Using buttons for scoring
    if (digitalRead(BUTTON_P1_PIN) == HIGH) {
      player1Score++;
      updateFoosballScore(currentMatchId, player1Score, player2Score);
    }
    if (digitalRead(BUTTON_P2_PIN) == HIGH) {
      player2Score++;
      updateFoosballScore(currentMatchId, player1Score, player2Score);
    }
    
    // Check for game end (first to 10)
    if (player1Score >= 10 || player2Score >= 10) {
      int winner = player1Score > player2Score ? 1 : 2;
      if (endGame(currentMatchId, winner)) {
        Serial.println("Game ended! Winner: Player " + String(winner));
        currentMatchId = "";
        player1Score = 0;
        player2Score = 0;
      }
    }
  }
  delay(100);
}
```

## Error Handling

```cpp
void handleHttpError(int httpCode) {
  switch (httpCode) {
    case -1:
      Serial.println("Connection failed");
      break;
    case 401:
      Serial.println("Unauthorized");
      break;
    case 404:
      Serial.println("API endpoint not found");
      break;
    default:
      Serial.println("HTTP Error: " + String(httpCode));
  }
}
```

## Best Practices

1. **Error Handling**:
   - Always check WiFi connection status
   - Handle HTTP response codes
   - Implement reconnection logic

2. **Security**:
   - Use HTTPS when possible
   - Implement request signing
   - Don't hardcode sensitive data

3. **Performance**:
   - Use static JSON documents when size is known
   - Implement proper delays to avoid flooding the server
   - Clean up HTTP client connections

4. **Reliability**:
   - Implement watchdog timer
   - Add error recovery mechanisms
   - Cache game state locally

## Troubleshooting

1. **Connection Issues**:
   - Verify WiFi credentials
   - Check server URL and port
   - Ensure ESP32 is within WiFi range

2. **RFID Problems**:
   - Verify wiring connections
   - Check if card is compatible
   - Test RFID module with basic read example

3. **Server Communication**:
   - Verify API endpoints
   - Check JSON formatting
   - Monitor serial output for errors 