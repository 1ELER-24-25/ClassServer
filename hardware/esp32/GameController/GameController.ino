#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <MFRC522.h>
#include <SPI.h>

// Network configuration
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* serverUrl = "http://your-server:3000/api";

// Pin definitions
#define SS_PIN    5  // SDA pin for RFID
#define RST_PIN   22 // RST pin for RFID
#define BTN_P1    12 // Score button for Player 1
#define BTN_P2    14 // Score button for Player 2
#define LED_WIFI  2  // WiFi status LED
#define LED_GAME  4  // Game status LED

// Test mode configuration
bool testMode = true;  // Set to true to enable test mode
String inputString = "";
bool stringComplete = false;

// Game states
enum GameState {
  WAITING_P1,
  WAITING_P2,
  GAME_ACTIVE,
  GAME_ENDED
};

// Global variables
MFRC522 rfid(SS_PIN, RST_PIN);
GameState currentState = WAITING_P1;
String currentMatchId = "";
String player1Uid = "";
String player2Uid = "";
int player1Score = 0;
int player2Score = 0;
unsigned long lastWifiCheck = 0;
unsigned long lastButtonCheck = 0;
bool buttonP1State = false;
bool buttonP2State = false;

void setup() {
  // Initialize serial communication
  Serial.begin(115200);
  inputString.reserve(200);
  
  // Initialize pins
  pinMode(BTN_P1, INPUT_PULLUP);
  pinMode(BTN_P2, INPUT_PULLUP);
  pinMode(LED_WIFI, OUTPUT);
  pinMode(LED_GAME, OUTPUT);
  
  if (!testMode) {
    // Initialize SPI and RFID
    SPI.begin();
    rfid.PCD_Init();
    
    // Connect to WiFi
    connectToWifi();
  } else {
    printTestInstructions();
  }
}

void printTestInstructions() {
  Serial.println("\n=== ClassServer Game Controller Test Mode ===");
  Serial.println("Available commands:");
  Serial.println("1. Scan RFID card:     rfid <uid>");
  Serial.println("2. Score point P1:     score1");
  Serial.println("3. Score point P2:     score2");
  Serial.println("4. End game:           end");
  Serial.println("5. Reset game:         reset");
  Serial.println("6. Show status:        status");
  Serial.println("7. Toggle WiFi:        wifi");
  Serial.println("8. Help:               help");
  Serial.println("=========================================");
}

void handleSerialCommand() {
  if (stringComplete) {
    inputString.trim();
    
    if (inputString.startsWith("rfid ")) {
      String uid = inputString.substring(5);
      handleTestRFID(uid);
    }
    else if (inputString == "score1") {
      handleTestScore(1);
    }
    else if (inputString == "score2") {
      handleTestScore(2);
    }
    else if (inputString == "end") {
      if (currentState == GAME_ACTIVE) {
        currentState = GAME_ENDED;
        Serial.println("Game ended manually");
      } else {
        Serial.println("Can't end game - no active game");
      }
    }
    else if (inputString == "reset") {
      resetGame();
      Serial.println("Game reset");
    }
    else if (inputString == "status") {
      printGameStatus();
    }
    else if (inputString == "wifi") {
      testMode = !testMode;
      Serial.println(testMode ? "Test mode enabled" : "Normal mode enabled");
    }
    else if (inputString == "help") {
      printTestInstructions();
    }
    else {
      Serial.println("Unknown command. Type 'help' for instructions.");
    }
    
    inputString = "";
    stringComplete = false;
  }
}

void handleTestRFID(String uid) {
  if (currentState == WAITING_P1) {
    player1Uid = uid;
    Serial.println("Player 1 registered with UID: " + uid);
    currentState = WAITING_P2;
  }
  else if (currentState == WAITING_P2) {
    if (uid != player1Uid) {
      player2Uid = uid;
      Serial.println("Player 2 registered with UID: " + uid);
      currentState = GAME_ACTIVE;
      Serial.println("Game started!");
    } else {
      Serial.println("Error: Player 2 cannot use the same card as Player 1");
    }
  }
  else {
    Serial.println("Cannot register players during active game");
  }
}

void handleTestScore(int player) {
  if (currentState != GAME_ACTIVE) {
    Serial.println("No active game");
    return;
  }
  
  if (player == 1) {
    player1Score++;
    Serial.println("Player 1 scored! Score: " + String(player1Score));
  } else {
    player2Score++;
    Serial.println("Player 2 scored! Score: " + String(player2Score));
  }
  
  if (player1Score >= 10 || player2Score >= 10) {
    currentState = GAME_ENDED;
    int winner = player1Score > player2Score ? 1 : 2;
    Serial.println("Game Over! Player " + String(winner) + " wins!");
    Serial.println("Type 'reset' to start a new game");
  }
}

void resetGame() {
  currentState = WAITING_P1;
  currentMatchId = "";
  player1Uid = "";
  player2Uid = "";
  player1Score = 0;
  player2Score = 0;
}

void printGameStatus() {
  Serial.println("\n=== Game Status ===");
  Serial.print("State: ");
  switch (currentState) {
    case WAITING_P1:
      Serial.println("Waiting for Player 1");
      break;
    case WAITING_P2:
      Serial.println("Waiting for Player 2");
      break;
    case GAME_ACTIVE:
      Serial.println("Game in progress");
      break;
    case GAME_ENDED:
      Serial.println("Game ended");
      break;
  }
  
  if (player1Uid != "") {
    Serial.println("Player 1 UID: " + player1Uid);
    Serial.println("Player 1 Score: " + String(player1Score));
  }
  
  if (player2Uid != "") {
    Serial.println("Player 2 UID: " + player2Uid);
    Serial.println("Player 2 Score: " + String(player2Score));
  }
  
  Serial.println("Test Mode: " + String(testMode ? "Enabled" : "Disabled"));
  Serial.println("==================");
}

void serialEvent() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    if (inChar == '\n') {
      stringComplete = true;
    } else {
      inputString += inChar;
    }
  }
}

void connectToWifi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    digitalWrite(LED_WIFI, !digitalRead(LED_WIFI));
    delay(500);
    Serial.print(".");
  }
  
  digitalWrite(LED_WIFI, HIGH);
  Serial.println("\nConnected to WiFi");
}

void checkWifiConnection() {
  if (millis() - lastWifiCheck >= 30000) { // Check every 30 seconds
    lastWifiCheck = millis();
    if (WiFi.status() != WL_CONNECTED) {
      digitalWrite(LED_WIFI, LOW);
      connectToWifi();
    }
  }
}

String readRFIDCard() {
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial())
    return "";

  String uid = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    if (rfid.uid.uidByte[i] < 0x10) uid += "0";
    uid += String(rfid.uid.uidByte[i], HEX);
  }
  
  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();
  
  return uid;
}

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

bool startGame(String p1Uid, String p2Uid) {
  if (WiFi.status() != WL_CONNECTED) return false;

  JsonDocument doc;
  doc["game_type"] = 2; // 2 for foosball
  doc["player1_uid"] = p1Uid;
  doc["player2_uid"] = p2Uid;

  String jsonString;
  serializeJson(doc, jsonString);

  HTTPClient http;
  http.begin(String(serverUrl) + "/matches/start");
  http.addHeader("Content-Type", "application/json");
  
  int httpCode = http.POST(jsonString);
  if (httpCode == HTTP_CODE_OK) {
    JsonDocument response;
    deserializeJson(response, http.getString());
    currentMatchId = response["match_id"].as<String>();
    http.end();
    return true;
  }
  
  http.end();
  return false;
}

bool updateScore() {
  if (WiFi.status() != WL_CONNECTED) return false;

  JsonDocument doc;
  doc["player1_score"] = player1Score;
  doc["player2_score"] = player2Score;

  String jsonString;
  serializeJson(doc, jsonString);

  HTTPClient http;
  http.begin(String(serverUrl) + "/matches/" + currentMatchId + "/score");
  http.addHeader("Content-Type", "application/json");
  
  int httpCode = http.POST(jsonString);
  http.end();
  return httpCode == HTTP_CODE_OK;
}

bool endGame(int winner) {
  if (WiFi.status() != WL_CONNECTED) return false;

  JsonDocument doc;
  doc["winner"] = winner;

  String jsonString;
  serializeJson(doc, jsonString);

  HTTPClient http;
  http.begin(String(serverUrl) + "/matches/" + currentMatchId + "/end");
  http.addHeader("Content-Type", "application/json");
  
  int httpCode = http.POST(jsonString);
  http.end();
  
  if (httpCode == HTTP_CODE_OK) {
    currentState = WAITING_P1;
    currentMatchId = "";
    player1Uid = "";
    player2Uid = "";
    player1Score = 0;
    player2Score = 0;
    return true;
  }
  
  return false;
}

void handleWaitingP1() {
  digitalWrite(LED_GAME, millis() % 1000 < 500);
  String uid = readRFIDCard();
  if (uid != "") {
    JsonDocument userData;
    if (getUserFromRFID(uid, userData)) {
      player1Uid = uid;
      Serial.println("Player 1: " + userData["username"].as<String>());
      currentState = WAITING_P2;
    }
  }
}

void handleWaitingP2() {
  digitalWrite(LED_GAME, millis() % 500 < 250);
  String uid = readRFIDCard();
  if (uid != "" && uid != player1Uid) {
    JsonDocument userData;
    if (getUserFromRFID(uid, userData)) {
      player2Uid = uid;
      Serial.println("Player 2: " + userData["username"].as<String>());
      if (startGame(player1Uid, player2Uid)) {
        currentState = GAME_ACTIVE;
        digitalWrite(LED_GAME, HIGH);
      }
    }
  }
}

void handleGameActive() {
  // Handle button inputs with debouncing
  if (millis() - lastButtonCheck >= 50) {
    lastButtonCheck = millis();
    
    bool p1 = !digitalRead(BTN_P1);
    bool p2 = !digitalRead(BTN_P2);
    
    if (p1 && !buttonP1State) {
      player1Score++;
      updateScore();
    }
    if (p2 && !buttonP2State) {
      player2Score++;
      updateScore();
    }
    
    buttonP1State = p1;
    buttonP2State = p2;
    
    // Check for game end
    if (player1Score >= 10 || player2Score >= 10) {
      currentState = GAME_ENDED;
    }
  }
}

void handleGameEnded() {
  digitalWrite(LED_GAME, millis() % 200 < 100);
  int winner = player1Score > player2Score ? 1 : 2;
  if (endGame(winner)) {
    Serial.println("Game ended! Winner: Player " + String(winner));
    digitalWrite(LED_GAME, LOW);
  }
}

void handleGameState() {
  switch (currentState) {
    case WAITING_P1:
      handleWaitingP1();
      break;
      
    case WAITING_P2:
      handleWaitingP2();
      break;
      
    case GAME_ACTIVE:
      handleGameActive();
      break;
      
    case GAME_ENDED:
      handleGameEnded();
      break;
  }
}

void loop() {
  if (testMode) {
    handleSerialCommand();
  } else {
    checkWifiConnection();
    handleGameState();
  }
  delay(10);
} 