# 🎮 ClassServer

A modern game tracking system for competitive table games with real-time scoring and player rankings.

## 🌟 Features

- 🎯 **Real-time Game Tracking** - Currently supporting:
  - ⚽ Foosball
  - ♟️ Chess
- 🏆 **ELO Ranking System** - Competitive player rankings for each game
- 🔐 **RFID Authentication** - Quick and secure player identification
- 📊 **Live Statistics** - Track your performance and progress
- 🌐 **Web Interface** - Modern React-based dashboard

## 🛠️ Tech Stack

- **Backend:** Node.js + Express
- **Frontend:** React
- **Database:** PostgreSQL
- **ORM:** Sequelize
- **Hardware:** ESP32 Controllers
- **Server:** Ubuntu 22.04 LTS

## 🚀 Getting Started

### Prerequisites

- Node.js (LTS version)
- PostgreSQL
- ESP32 Development Board (for game controllers)

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/ClassServer.git
cd ClassServer
```

2. Install dependencies
```bash
npm install
```

3. Configure environment variables
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Start the server
```bash
npm run start
```

## 📐 System Architecture

```
┌─────────────────┐      ┌──────────────┐
│  ESP32 Devices  │ ──── │   REST API   │
└─────────────────┘      └──────┬───────┘
                                │
                          ┌─────┴───────┐
                          │  Database   │
                          └─────┬───────┘
                                │
                          ┌─────┴───────┐
                          │  Frontend   │
                          └─────────────┘
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 
