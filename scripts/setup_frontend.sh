#!/bin/bash

# Exit on any error
set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Get server address for API configuration
SERVER_ADDRESS=$(get_server_address)

# Create frontend directory
print_message "Creating frontend directory..."
mkdir -p /opt/ClassServer/frontend

# Create a simplified React frontend
print_message "Creating simplified React frontend..."
cd /opt/ClassServer/frontend

# Initialize a new React app with Vite using JavaScript and latest versions
print_message "Initializing new React app with latest dependencies..."
cat > package.json << EOF
{
  "name": "classserver-frontend",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.22.0",
    "axios": "^1.6.7"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.1",
    "vite": "^6.2.0"
  }
}
EOF

# Create Vite config
print_message "Creating Vite configuration..."
cat > vite.config.js << EOF
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000
  }
})
EOF

# Create index.html
print_message "Creating HTML template..."
cat > index.html << EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>ClassServer</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

# Create src directory structure
print_message "Creating source directory structure..."
mkdir -p /opt/ClassServer/frontend/src/{components,pages,assets}
mkdir -p /opt/ClassServer/frontend/public

# Create main.jsx
print_message "Creating main application file..."
cat > /opt/ClassServer/frontend/src/main.jsx << EOF
import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </React.StrictMode>
)
EOF

# Create App.jsx
print_message "Creating App component..."
cat > /opt/ClassServer/frontend/src/App.jsx << EOF
import React from 'react'
import { Routes, Route, Link } from 'react-router-dom'
import Dashboard from './pages/Dashboard'
import Leaderboard from './pages/Leaderboard'
import './App.css'

function App() {
  return (
    <div className="app">
      <header className="header">
        <div className="logo">ClassServer</div>
        <nav className="nav">
          <Link to="/" className="nav-link">Dashboard</Link>
          <Link to="/leaderboard" className="nav-link">Leaderboard</Link>
        </nav>
      </header>
      
      <main className="main-content">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/leaderboard" element={<Leaderboard />} />
        </Routes>
      </main>
      
      <footer className="footer">
        <p>&copy; 2025 ClassServer</p>
      </footer>
    </div>
  )
}

export default App
EOF

# Create CSS files
print_message "Creating CSS styles..."
cat > /opt/ClassServer/frontend/src/index.css << EOF
:root {
  --primary-color: #2563EB;
  --secondary-color: #DC2626;
  --background-color: #F8FAFC;
  --text-color: #1E293B;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen,
    Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  background-color: var(--background-color);
  color: var(--text-color);
  line-height: 1.6;
}
EOF

cat > /opt/ClassServer/frontend/src/App.css << EOF
.app {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 2rem;
  background-color: white;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.logo {
  font-size: 1.5rem;
  font-weight: bold;
  color: var(--primary-color);
}

.nav {
  display: flex;
  gap: 1.5rem;
}

.nav-link {
  color: var(--text-color);
  text-decoration: none;
  font-weight: 500;
  padding: 0.5rem;
  border-radius: 0.5rem;
  transition: background-color 0.2s;
}

.nav-link:hover {
  background-color: rgba(37, 99, 235, 0.1);
}

.main-content {
  flex: 1;
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
  width: 100%;
}

.footer {
  padding: 1rem 2rem;
  background-color: white;
  text-align: center;
  border-top: 1px solid #e5e7eb;
}

.card {
  background-color: white;
  border-radius: 0.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  padding: 1.5rem;
  margin-bottom: 1.5rem;
}

.card-title {
  font-size: 1.25rem;
  font-weight: 600;
  margin-bottom: 1rem;
  color: var(--primary-color);
}

.btn {
  display: inline-block;
  background-color: var(--primary-color);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  border: none;
  cursor: pointer;
  font-weight: 500;
  text-decoration: none;
  transition: background-color 0.2s;
}

.btn:hover {
  background-color: #1d4ed8;
}

.btn-secondary {
  background-color: var(--secondary-color);
}

.btn-secondary:hover {
  background-color: #b91c1c;
}

.table {
  width: 100%;
  border-collapse: collapse;
}

.table th,
.table td {
  padding: 0.75rem;
  text-align: left;
  border-bottom: 1px solid #e5e7eb;
}

.table th {
  font-weight: 600;
  background-color: #f9fafb;
}
EOF

# Create page components
print_message "Creating page components..."
cat > /opt/ClassServer/frontend/src/pages/Dashboard.jsx << EOF
import React from 'react'

function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      <div className="card">
        <h2 className="card-title">Welcome to ClassServer</h2>
        <p>This is a system for registering and managing board game competitions.</p>
        <p>Currently supported games:</p>
        <ul>
          <li>Foosball</li>
          <li>Chess</li>
        </ul>
      </div>
      
      <div className="card">
        <h2 className="card-title">Active Games</h2>
        <p>No active games at the moment.</p>
        <button className="btn">Start New Game</button>
      </div>
    </div>
  )
}

export default Dashboard
EOF

cat > /opt/ClassServer/frontend/src/pages/Leaderboard.jsx << EOF
import React, { useState } from 'react'

function Leaderboard() {
  const [selectedGame, setSelectedGame] = useState('foosball')
  
  // Mock data for demonstration
  const leaderboardData = {
    foosball: [
      { id: 1, name: 'Player 1', rating: 1450, wins: 15, losses: 5 },
      { id: 2, name: 'Player 2', rating: 1380, wins: 12, losses: 8 },
      { id: 3, name: 'Player 3', rating: 1320, wins: 10, losses: 10 },
      { id: 4, name: 'Player 4', rating: 1280, wins: 8, losses: 12 },
      { id: 5, name: 'Player 5', rating: 1220, wins: 6, losses: 14 }
    ],
    chess: [
      { id: 1, name: 'Player 3', rating: 1520, wins: 18, losses: 2 },
      { id: 2, name: 'Player 1', rating: 1480, wins: 16, losses: 4 },
      { id: 3, name: 'Player 5', rating: 1350, wins: 11, losses: 9 },
      { id: 4, name: 'Player 2', rating: 1300, wins: 9, losses: 11 },
      { id: 5, name: 'Player 4', rating: 1250, wins: 7, losses: 13 }
    ]
  }
  
  return (
    <div>
      <h1>Leaderboard</h1>
      
      <div className="card">
        <h2 className="card-title">Game Selection</h2>
        <div className="game-selector">
          <button 
            className={\`btn \${selectedGame === 'foosball' ? '' : 'btn-secondary'}\`}
            onClick={() => setSelectedGame('foosball')}
          >
            Foosball
          </button>
          <button 
            className={\`btn \${selectedGame === 'chess' ? '' : 'btn-secondary'}\`}
            onClick={() => setSelectedGame('chess')}
            style={{ marginLeft: '10px' }}
          >
            Chess
          </button>
        </div>
      </div>
      
      <div className="card">
        <h2 className="card-title">{selectedGame.charAt(0).toUpperCase() + selectedGame.slice(1)} Leaderboard</h2>
        <table className="table">
          <thead>
            <tr>
              <th>Rank</th>
              <th>Player</th>
              <th>Rating</th>
              <th>Wins</th>
              <th>Losses</th>
            </tr>
          </thead>
          <tbody>
            {leaderboardData[selectedGame].map((player, index) => (
              <tr key={player.id}>
                <td>{index + 1}</td>
                <td>{player.name}</td>
                <td>{player.rating}</td>
                <td>{player.wins}</td>
                <td>{player.losses}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

export default Leaderboard
EOF

# Create .env file for API URL
print_message "Creating environment configuration..."
cat > /opt/ClassServer/frontend/.env << EOF
VITE_API_URL=http://${SERVER_ADDRESS}/api
EOF

# Install dependencies
print_message "Installing dependencies..."
npm install || {
    print_error "Failed to install dependencies"
    exit 1
}

# Fix vulnerabilities
print_message "Fixing any vulnerabilities..."
npm audit fix --force || {
    print_warning "Could not fix all vulnerabilities automatically"
}

# Build the frontend
print_message "Building frontend..."
npm run build || {
    print_error "Failed to build frontend"
    exit 1
}

# Set permissions
print_message "Setting frontend permissions..."
chown -R www-data:www-data /opt/ClassServer/frontend/dist

print_message "Frontend setup completed successfully!" 