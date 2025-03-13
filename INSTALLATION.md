# Installation Guide :gear:

This guide walks you through installing **ClassServer**, the IoT Gaming System for classrooms, on Linux or Windows. Commands are provided in easy-to-copy format for your terminal of choice. Let’s get started! :rocket:

---

## :clipboard: Prerequisites

Before you begin, ensure you have these tools installed:

- **Git**: For cloning the repository.
  - :penguin: **Linux**: Install via package manager (e.g., `sudo apt install git`).
  - :window: **Windows**: Download [Git for Windows](https://git-scm.com/download/win) (includes Git Bash).
- **Docker & Docker Compose**: For running the system.
  - :penguin: **Linux**: Install Docker and Docker Compose (see below).
  - :window: **Windows**: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/), enable WSL 2, and start it.

---

## :wrench: Step-by-Step Installation

### 1. Install Prerequisites

#### :penguin: Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install -y git docker.io docker-compose
sudo systemctl enable --now docker
```

#### :window: Windows
1. Install Git for Windows from [git-scm.com](https://git-scm.com/download/win).
2. Install Docker Desktop from [docker.com](https://www.docker.com/products/docker-desktop/).
3. Enable WSL 2 backend during setup (recommended).
4. Start Docker Desktop from the system tray.

:information_source: **Windows Note**: Run commands in Git Bash, PowerShell, or CMD. Ensure Docker Desktop is running before proceeding.

### 2. Clone the Repository
```bash
git clone https://github.com/1ELER-24-25/ClassServer.git
cd ClassServer
```

#### :window: Windows PowerShell Alternative:
```powershell
git clone https://github.com/1ELER-24-25/ClassServer.git
cd ClassServer
```

### 3. Set Up Environment Variables

Copy the example `.env` file and edit it with your credentials:

#### Bash:
```bash
cp .env.example .env
```

#### Edit `.env`:
- :penguin: **Linux**: Use `nano .env` or your preferred editor.
- :window: **Windows**: Use `notepad .env` (Git Bash/PowerShell) or any text editor.

#### :window: Windows PowerShell Alternative:
```powershell
copy .env.example .env
notepad .env
```

### 4. Start the System

#### Bash:
```bash
docker-compose up -d
```

:window: **Windows Note**: Ensure Docker Desktop is running. Run this in Git Bash, PowerShell, or CMD. Allow firewall access if prompted (ports 5000, 1880, etc.).

### 5. Verify Installation

Check these URLs in your browser:

- :earth_americas: **Web App**: [http://localhost:5000](http://localhost:5000)
- :gear: **Node-RED**: [http://localhost:1880](http://localhost:1880)
- :zap: **InfluxDB**: [http://localhost:8086](http://localhost:8086)
- :hammer: **Adminer**: [http://localhost:8080](http://localhost:8080)

If they load, you’re good to go! :tada:

---

## :warning: Troubleshooting

### Docker Not Running:
- :penguin: **Linux**: `sudo systemctl start docker`
- :window: **Windows**: Start Docker Desktop from the system tray.

### Port Conflicts:
Check if ports (e.g., 5000) are in use:

#### Bash:
```bash
netstat -tuln | grep 5000  # Linux
netstat -aon | findstr 5000  # Windows PowerShell
```

Stop conflicting processes or edit `docker-compose.yml`.

### Permission Issues:
- :penguin: **Linux**: Add your user to the Docker group: `sudo usermod -aG docker $USER` and reboot.
- :window: **Windows**: Run terminal as Administrator.

---

## :information_source: Additional Notes

- **ESP32 Setup**: Flash your boards with firmware (details in `PROJECT_DESCRIPTION.md`).
- **Full Details**: See `PROJECT_DESCRIPTION.md` for the complete project setup.

