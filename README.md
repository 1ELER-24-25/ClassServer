# ClassServer :school: :computer:

![Under Construction](https://img.shields.io/badge/Status-Under%20Construction-orange?style=for-the-badge)  
*Bringing IoT Gaming to the Classroom – One Move at a Time!*

---

## :rocket: Welcome to ClassServer!

**ClassServer** is an IoT-powered gaming system designed for classroom fun and learning. Hosted at `https://github.com/1ELER-24-25/ClassServer`, it transforms physical games like chess (and soon foosball!) into a digital experience with real-time tracking, ELO rankings, and a slick web interface. Built for students and teachers at **1ELER-24-25**, it’s a work in progress—and we’re excited to see it grow!

> :warning: **Note**: This project is under active development. Features are being added, bugs are being squashed, and awesomeness is being crafted! Check back often for updates.

---

## :star2: What’s Cooking?

- :chess_pawn: **Chess Awesomeness**: Play on ESP32 boards with RFID registration, move validation, and multiple endgame options (checkmate, forfeit, draw, timeout, cancel).
- :trophy: **Leaderboards**: Show off your skills with classroom-wide rankings.
- :busts_in_silhouette: **Profiles**: Track your games and ELO via a user-friendly web app.
- :wrench: **Admin Tools**: Delete games and tweak settings (coming soon!).
- :package: **Dockerized**: Easy setup for classroom deployment.

🔍 **Details**: Dive into the full vision in [`PROJECT_DESCRIPTION.md`](./PROJECT_DESCRIPTION.md).

---

## :gear: Tech Stack Sneak Peek

- 🔌 **ESP32 Boards**: The heart of our game boards.
- :speech_balloon: **Mosquitto**: MQTT magic on port `1883`.
- :zap: **InfluxDB**: Real-time game tracking (`8086`).
- 📊 **Grafana**: Beautiful data visualization (`3000`).
- :elephant: **PostgreSQL**: Persistent data home (`5432`).
- :earth_americas: **Flask**: Web app on `5000`.
- :whale: **Docker**: Keeping it all together.

---

## :construction: Under Construction

This classroom server is still being built! Here’s what’s in progress:

- :hammer: Wiring up ESP32 boards with sensors and buttons.
- :gear: Crafting Node-RED flows for chess logic.
- :art: Designing the Flask web interface.
- :bug: Squashing bugs and testing in the wild.

**Want to help?** Join the fun—fork, clone, and contribute! :raised_hands:

---

## :rocket: Quick Start (Coming Soon!)

1. Clone it: `git clone https://github.com/1ELER-24-25/ClassServer.git`
2. Set it up: `docker-compose up -d`
3. Play: Visit `http://localhost:5000` (once it’s ready!).

Full setup lives in [`PROJECT_DESCRIPTION.md`](./PROJECT_DESCRIPTION.md).

---

## :eyes: Stay Tuned!

ClassServer is evolving fast at **1ELER-24-25**. Watch this repo for updates, star it :star:, and let’s make gaming in the classroom epic! Questions? Open an issue or ping us!

---

*Last Updated: March 13, 2025*  
:school_satchel: **1ELER-24-25 Classroom Project**
