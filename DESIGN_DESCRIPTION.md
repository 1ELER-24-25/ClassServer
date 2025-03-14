# Design Description :blueprint: :school:

This **Design Description** outlines the architecture and solutions for **ClassServer**, an IoT Gaming System for the 1ELER-24-25 classroom. Hosted at `https://github.com/1ELER-24-25/ClassServer`, it’s designed to track physical games (starting with chess) using ESP32 boards, offering real-time validation, ELO rankings, and a web interface. This document details the tech stack and agreed-upon solutions to guide development.

---

## :dart: Project Goals

- :chess_pawn: Enable real-time tracking and validation of chess games in a classroom setting.
- :trophy: Provide ELO-based rankings and user profiles for competitive fun.
- :earth_americas: Deliver an intuitive web interface for players and admins.
- :package: Ensure easy deployment via Docker for classroom use.
- :arrows_counterclockwise: Scale to support multiple boards and future games (e.g., foosball).

---

## :building_construction: System Architecture

### Overview
ClassServer connects ESP32-based game boards to a Dockerized server via MQTT, processing game logic in Node-RED, storing data in InfluxDB (real-time) and PostgreSQL (persistent), and serving a Flask web app.

- **ESP32 Boards** :arrow_right: **Mosquitto (MQTT)** :arrow_right: **Node-RED** :arrow_right: **InfluxDB/PostgreSQL** :arrow_right: **Flask Web App**

---

## :gear: Technology Stack

### :microchip: Hardware
- **ESP32 Boards**:
  - RFID readers for player registration.
  - Buttons: Start, Forfeit, Draw, Cancel.
  - Mode switch: Casual/Blitz/Classical.
  - LEDs: Game status feedback.

### :cloud: Software Stack
- **:speech_balloon: Mosquitto** (Port: `1883`):
  - MQTT broker for ESP32-server communication.
- **:gear: Node-RED** (Port: `1880`):
  - Processes game logic with `chess.js`.
  - Logs to InfluxDB and updates PostgreSQL.
- **:floppy_disk: Databases**:
  - **:zap: InfluxDB** (Port: `8086`):
    - Real-time move logging for active games.
  - **:elephant: PostgreSQL** (Port: `5432`):
    - Persistent storage for finished games, users, ELO.
- **:earth_americas: Flask** (Port: `5000`):
  - Web app with Flask-Login for user authentication.
- **:hammer: Adminer** (Port: `8080`):
  - PostgreSQL management interface.
- **:whale: Docker Compose**:
  - Orchestrates all services.

---

## :jigsaw: Solutions & Design Decisions

### :chess_pawn: Chessboard Functionality
- **Player Registration**:
  - RFID scan: First player = White, second = Black.
  - Future: Tournament mode for assigned colors.
- **Game Start**:
  - “Start” button triggers MQTT message after RFID.
- **Move Tracking**:
  - Sensors detect moves, sent via MQTT for validation.
- **End Conditions**:
  - Checkmate (server via `chess.js`).
  - Forfeit (button press).
  - Remis (draw, confirmed by both players).
  - Timeout (ESP32-enforced time limits).
  - Cancel (button to abort).
- **Timed Modes**:
  - Switch sets Casual (no limit), Blitz (5 min), Classical (30 min).
  - ESP32 tracks and enforces time.

### :radio: MQTT Communication
- **QoS**: 1 (at least once delivery).
- **Topics & Payloads**:
  - **Outbound (ESP32 → Server)**:
    - `games/chess/start`: `{"board_id": "Board-001", "rfid_white": "abc123", "rfid_black": "xyz789", "mode": "blitz", "time_limit": 300}`
    - `games/chess/move`: `{"board_id": "Board-001", "game_id": "123", "rfid": "abc123", "move": "e2e4"}`
    - `games/chess/forfeit`: `{"board_id": "Board-001", "game_id": "123", "rfid": "abc123"}`
    - `games/chess/remis`: `{"board_id": "Board-001", "game_id": "123", "rfid": "abc123"}` (twice for draw).
    - `games/chess/timeout`: `{"board_id": "Board-001", "game_id": "123", "rfid": "abc123"}`
    - `games/chess/cancel`: `{"board_id": "Board-001", "game_id": "123", "rfid": "abc123"}`
  - **Inbound (Server → ESP32)**:
    - Topic: `games/chess/response/<board_id>/<game_id>` (e.g., `games/chess/response/Board-001/123`).
    - Examples: `{"status": "legal"}`, `{"status": "checkmate", "winner": "abc123"}`.
- **Board ID**: Unique per ESP32 (e.g., “Board-001”) for multi-board support.

### :floppy_disk: Data Storage
- **:zap: InfluxDB**:
  - **Role**: Real-time scorekeeper for active games.
  - **Measurement**: `chess_moves`.
  - **Tags**: `game_id`, `board_id`, `player_rfid`, `status`.
  - **Fields**: `move`.
  - **Retention**: 7 days.
  - **Example**: `chess_moves,game_id=123,board_id=Board-001,player_rfid=abc123,status=legal move=e2e4`.
- **:elephant: PostgreSQL**:
  - **Role**: Persistent storage for finished games, users, ELO.
  - **Tables**:
    - `users`: RFID, username, password_hash, profile_picture.
    - `games`: Game metadata, status, winner, `board_id`, `elo_change` (JSONB), `deleted` flag.
    - `elo_ratings`: User ELO per game type.
  - **Game Deletion**: Soft delete (`deleted = TRUE`) with ELO reversal via `elo_change`.

### :earth_americas: Web Interface
- **Framework**: Flask.
- **Pages**:
  - `/`: Landing page with intro, leaderboards, links.
  - `/server-info`: Ports (1883, 1880, etc.), IP (`localhost`), setup tips.
  - `/mqtt-docs`: MQTT protocol details.
  - `/login`: RFID/password form.
  - `/profile`: User info, game history, ELO stats.
- **Maintenance Links**:
  - Node-RED: `http://localhost:1880`.
  - InfluxDB: `http://localhost:8086`.
  - Adminer: `http://localhost:8080`.

### :arrows_counterclockwise: Workflow
1. **Game Start**: ESP32 sends `start` → Node-RED assigns `game_id` → PostgreSQL stores game.
2. **Active Game**: Moves sent via MQTT → Node-RED validates → InfluxDB logs → Game state held in memory.
3. **Game End**: Node-RED updates PostgreSQL with final state (`status`, `winner_id`, `elo_change`).
4. **Web Access**: Flask queries PostgreSQL for leaderboards, profiles.

---

## :file_folder: File Structure
ClassServer/
├── docker-compose.yml         :whale:
├── README.md                 :book:
├── installation.md           :wrench:
├── .env.example              :key:
├── .gitignore                :no_entry_sign:
├── mosquitto/
│   └── mosquitto.conf        :speech_balloon:
├── postgres/
│   └── init.sql              :elephant:
├── nodered/
│   ├── flows.json            :gear:
│   └── Dockerfile            :package:
├── webapp/
│   ├── app.py                :earth_americas:
│   ├── Dockerfile            :package:
│   ├── requirements.txt      :page_facing_up:
│   └── templates/            :page_with_curl:
└── docs/
└── DESIGN_DESCRIPTION.md  :blueprint:


---

## :hammer: Implementation Details

### :microchip: ESP32
- Hardcode `board_id` (e.g., “Board-001”).
- MQTT client sends/receives messages.
- Button handlers for Start, Forfeit, Draw, Cancel.
- Timer logic for Blitz/Classical modes.

### :gear: Node-RED
- Flows for:
  - Game start (`games/chess/start` → PostgreSQL insert).
  - Move validation (`chess.js`, logs to InfluxDB, updates game state).
  - End conditions (updates PostgreSQL with `elo_change`).
- Dependencies: `chess.js`, `node-red-contrib-influxdb`, `node-red-node-postgres`.

### :earth_americas: Flask
- Routes: `/`, `/server-info`, `/mqtt-docs`, `/login`, `/profile`.
- Queries PostgreSQL for leaderboards, user data.
- Flask-Login for authentication.

### :floppy_disk: Databases
- **InfluxDB**: Logs moves in real-time, expires after 7 days.
- **PostgreSQL**: Stores final game state, supports soft deletion.

---

## :rocket: Deployment

- **Docker Compose**: Single command (`docker-compose up -d`) launches all services.
- **Ports**: Exposed as 1883 (MQTT), 1880 (Node-RED), 5000 (Flask), 8086 (InfluxDB), 8080 (Adminer).
- **Environment**: Configured via `.env` (see `installation.md`).

---

## :fast_forward: Future Enhancements

- :soccer: Add foosball support (new MQTT topics, DB entries).
- :wrench: Flask `/admin` page for game deletion.
- :crown: Tournament mode with color assignment.
- :lock: MQTT authentication for security.

---

This design is your roadmap to build **ClassServer**—a robust, scalable IoT gaming platform for 1ELER-24-25. Start coding, and let’s make it shine! :star: