#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <MFRC522.h>
#include <SPI.h>

// Network configuration
const char* ssid = "YourWiFiSSID";  // Replace with your WiFi name
const char* password = "YourWiFiPassword";  // Replace with your WiFi password
const char* serverUrl = "http://localhost:8000";  // Your ClassServer backend URL

// Game configuration
const int GAME_TYPE_FOOSBALL = 2;
const int GAME_TYPE_CHESS = 1;
int currentGameType = GAME_TYPE_FOOSBALL;  // Default to foosball

// Pin definitions
#define SS_PIN    5  // SDA pin for RFID
#define RST_PIN   22 // RST pin for RFID
#define LED_RED   25  // Error/Not Ready
#define LED_GREEN 26  // Success/Ready
#define LED_BLUE  27  // Processing
#define BTN_P1    32  // Score button for Player 1
#define BTN_P2    33  // Score button for Player 2

// Test mode configuration
bool testMode = true;  // Set to true to enable test mode
String inputString = "";
bool stringComplete = false;

// Game states
enum GameState {
  WAITING_CARD,
  PROCESSING_CARD,
  SHOWING_NEW_USER,
  GAME_ACTIVE,
  GAME_ENDED
};

// Global variables
MFRC522 rfid(SS_PIN, RST_PIN);
GameState currentState = WAITING_CARD;
String currentMatchId = "";
String player1Uid = "";
String player2Uid = "";
int player1Score = 0;
int player2Score = 0;
unsigned long lastCardCheck = 0;
const int cardCheckDelay = 1000;  // Time between card checks
String currentUserName = "";
bool isNewUser = false;

void setup() {
  // Initialize serial communication
  Serial.begin(115200);
  inputString.reserve(200);
  
  // Initialize pins
  pinMode(LED_RED, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_BLUE, OUTPUT);
  pinMode(BTN_P1, INPUT_PULLUP);
  pinMode(BTN_P2, INPUT_PULLUP);
  
  if (!testMode) {
    // Initialize SPI and RFID
    SPI.begin();
    rfid.PCD_Init();
    
    // Connect to WiFi
    connectToWiFi();
  } else {
    printTestInstructions();
  }
  
  // Initial LED state
  setLEDState(LED_RED);  // Start with red LED (not ready)
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
  Serial.println("8. Set game type:      type <1=chess|2=foosball>");
  Serial.println("9. Help:               help");
  Serial.println("\nAPI Endpoints Used:");
  Serial.println("- GET  /users/rfid/{uid}         - Get user info");
  Serial.println("- POST /matches/start            - Start new game");
  Serial.println("- POST /matches/{id}/score       - Update score");
  Serial.println("- POST /matches/{id}/end         - End game");
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
    else if (inputString.startsWith("type ")) {
      int type = inputString.substring(5).toInt();
      if (type == GAME_TYPE_CHESS || type == GAME_TYPE_FOOSBALL) {
        currentGameType = type;
        Serial.println("Game type set to: " + String(type == GAME_TYPE_CHESS ? "Chess" : "Foosball"));
      } else {
        Serial.println("Invalid game type. Use 1 for Chess or 2 for Foosball");
      }
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
  if (currentState == WAITING_CARD) {
    handleWaitingCard();
  } else {
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
  currentState = WAITING_CARD;
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
    case WAITING_CARD:
      Serial.println("Waiting for card");
      break;
    case PROCESSING_CARD:
      Serial.println("Processing card");
      break;
    case SHOWING_NEW_USER:
      Serial.println("Showing new user");
      break;
    case GAME_ACTIVE:
      Serial.println("Game in progress");
      break;
    case GAME_ENDED:
      Serial.println("Game ended");
      break;
  }
  
  Serial.println("Game Type: " + String(currentGameType == GAME_TYPE_CHESS ? "Chess" : "Foosball"));
  
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

void connectToWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  
  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
    setLEDState(LED_RED);
    delay(250);
    setLEDState(-1);
    delay(250);
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nConnected to WiFi");
    setLEDState(LED_GREEN);
  } else {
    Serial.println("\nFailed to connect to WiFi");
    setLEDState(LED_RED);
  }
}

void handleWaitingCard() {
  setLEDState(LED_GREEN);  // Ready to read card
  
  if (millis() - lastCardCheck < cardCheckDelay) return;
  
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) return;
  
  String uid = getCardUID();
  setLEDState(LED_BLUE);  // Processing
  currentState = PROCESSING_CARD;
  
  // Authenticate card with server
  authenticateCard(uid);
  
  lastCardCheck = millis();
  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();
}

void handleProcessingCard() {
  // This state is mainly handled by the authenticateCard callback
  // The LED is already blue from the previous state
  delay(100);  // Small delay to prevent busy waiting
}

void handleShowingNewUser() {
  // Blink blue LED to indicate new user
  static unsigned long lastBlink = 0;
  const int blinkInterval = 500;
  
  if (millis() - lastBlink >= blinkInterval) {
    static bool ledState = false;
    setLEDState(ledState ? LED_BLUE : -1);
    ledState = !ledState;
    lastBlink = millis();
  }
  
  // Show temporary username for 5 seconds
  static unsigned long showStart = millis();
  if (millis() - showStart >= 5000) {
    currentState = GAME_ACTIVE;
    setLEDState(LED_GREEN);
  }
  
  // Print temporary credentials to Serial for testing
  if (isNewUser) {
    Serial.println("New user created!");
    Serial.println("Username: " + currentUserName);
    Serial.println("Default password: 1111");
    isNewUser = false;  // Reset flag after showing once
  }
}

void authenticateCard(String uid) {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  String url = String(serverUrl) + "/auth/rfid/auth";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  // Create JSON payload
  StaticJsonDocument<200> doc;
  doc["rfid_uid"] = uid;
  String jsonString;
  serializeJson(doc, jsonString);
  
  int httpCode = http.POST(jsonString);
  
  if (httpCode == HTTP_CODE_OK) {
    String payload = http.getString();
    StaticJsonDocument<512> response;
    DeserializationError error = deserializeJson(response, payload);
    
    if (!error) {
      bool isNewUser = response["is_new_user"];
      const char* username = response["user"]["username"];
      currentUserName = String(username);
      
      if (isNewUser) {
        currentState = SHOWING_NEW_USER;
        isNewUser = true;
        const char* tempPassword = response["temp_password"];
        Serial.println("New user created!");
        Serial.println("Username: " + String(username));
        Serial.println("Temporary password: " + String(tempPassword));
      } else {
        if (player1Uid.length() == 0) {
          player1Uid = uid;
          Serial.println("Player 1 registered: " + currentUserName);
        } else if (player2Uid.length() == 0 && uid != player1Uid) {
          player2Uid = uid;
          Serial.println("Player 2 registered: " + currentUserName);
          // Start the game when both players are registered
          startGame();
        }
      }
      setLEDState(LED_GREEN);
    } else {
      Serial.println("JSON parsing failed");
      setLEDState(LED_RED);
    }
  } else {
    Serial.println("Authentication failed: " + String(httpCode));
    setLEDState(LED_RED);
  }
  
  http.end();
}

void startGame() {
  if (WiFi.status() != WL_CONNECTED) return;
  
  HTTPClient http;
  String url = String(serverUrl) + "/matches/start";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  // Create JSON payload
  StaticJsonDocument<200> doc;
  doc["game_type"] = currentGameType;
  doc["player1_uid"] = player1Uid;
  doc["player2_uid"] = player2Uid;
  String jsonString;
  serializeJson(doc, jsonString);
  
  int httpCode = http.POST(jsonString);
  
  if (httpCode == HTTP_CODE_OK) {
    String payload = http.getString();
    StaticJsonDocument<200> response;
    DeserializationError error = deserializeJson(response, payload);
    
    if (!error) {
      currentMatchId = response["match_id"].as<String>();
      currentState = GAME_ACTIVE;
      Serial.println("Game started! Match ID: " + currentMatchId);
      setLEDState(LED_GREEN);
    } else {
      Serial.println("JSON parsing failed");
      setLEDState(LED_RED);
    }
  } else {
    Serial.println("Failed to start game: " + String(httpCode));
    setLEDState(LED_RED);
  }
  
  http.end();
}

void handleGameActive() {
  // Handle button inputs with debouncing
  static unsigned long lastButtonCheck = 0;
  const int debounceDelay = 50;
  
  if (millis() - lastButtonCheck < debounceDelay) return;
  
  bool p1 = !digitalRead(BTN_P1);
  bool p2 = !digitalRead(BTN_P2);
  
  if (p1) {
    player1Score++;
    updateScore();
  }
  if (p2) {
    player2Score++;
    updateScore();
  }
  
  // Check for game end
  if (player1Score >= 10 || player2Score >= 10) {
    currentState = GAME_ENDED;
  }
  
  lastButtonCheck = millis();
}

void handleGameEnded() {
  digitalWrite(LED_GREEN, LOW);
  int winner = player1Score > player2Score ? 1 : 2;
  if (endGame(winner)) {
    Serial.println("Game ended! Winner: Player " + String(winner));
    digitalWrite(LED_GREEN, LOW);
  }
}

void handleGameState() {
  switch (currentState) {
    case WAITING_CARD:
      handleWaitingCard();
      break;
    case PROCESSING_CARD:
      handleProcessingCard();
      break;
    case SHOWING_NEW_USER:
      handleShowingNewUser();
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
    // Check WiFi connection
    if (WiFi.status() != WL_CONNECTED) {
      connectToWiFi();
      return;
    }
    handleGameState();
  }
  delay(10);
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

void setLEDState(int led) {
  digitalWrite(LED_RED, LOW);
  digitalWrite(LED_GREEN, LOW);
  digitalWrite(LED_BLUE, LOW);
  if (led >= 0) {
    digitalWrite(led, HIGH);
  }
}

bool updateScore() {
  if (WiFi.status() != WL_CONNECTED) return false;

  HTTPClient http;
  String url = String(serverUrl) + "/matches/" + currentMatchId + "/score";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  // Create JSON payload
  StaticJsonDocument<200> doc;
  doc["player1_score"] = player1Score;
  doc["player2_score"] = player2Score;
  String jsonString;
  serializeJson(doc, jsonString);
  
  int httpCode = http.POST(jsonString);
  
  if (httpCode == HTTP_CODE_OK) {
    Serial.println("Score updated successfully");
    // Check for game end
    if (player1Score >= 10 || player2Score >= 10) {
      currentState = GAME_ENDED;
      int winner = player1Score > player2Score ? 1 : 2;
      endGame(winner);
    }
    return true;
  } else {
    Serial.println("Failed to update score: " + String(httpCode));
    return false;
  }
}

bool endGame(int winner) {
  if (WiFi.status() != WL_CONNECTED) return false;

  HTTPClient http;
  String url = String(serverUrl) + "/matches/" + currentMatchId + "/end";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  // Create JSON payload
  StaticJsonDocument<200> doc;
  doc["winner"] = winner;
  String jsonString;
  serializeJson(doc, jsonString);
  
  int httpCode = http.POST(jsonString);
  
  if (httpCode == HTTP_CODE_OK) {
    Serial.println("Game ended successfully! Winner: Player " + String(winner));
    // Reset game state
    currentState = WAITING_CARD;
    currentMatchId = "";
    player1Uid = "";
    player2Uid = "";
    player1Score = 0;
    player2Score = 0;
    return true;
  } else {
    Serial.println("Failed to end game: " + String(httpCode));
    return false;
  }
} 