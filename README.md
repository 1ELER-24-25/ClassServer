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
- **Frontend:** React + Tailwind CSS
- **Database:** PostgreSQL + Sequelize ORM
- **Hardware:** ESP32 Controllers
- **Server:** Ubuntu 22.04 LTS

## 🚀 Getting Started

### Quick Start

1. Clone the repository
```bash
git clone https://github.com/yourusername/ClassServer.git
cd ClassServer
```

2. Install dependencies and set up the project
```bash
npm install
cp .env.example .env
```

3. Start development servers
```bash
npm run start
```

The application will be available at:
- Frontend: http://localhost:5173
- Backend API: http://localhost:3000

For detailed installation instructions, including prerequisites, database setup, and hardware configuration, please see our [Installation Guide](INSTALLATION.md).

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

This project is licensed under the MIT License

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 
