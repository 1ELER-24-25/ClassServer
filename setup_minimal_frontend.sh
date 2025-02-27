#!/bin/bash

# Create a minimal frontend that will build successfully
echo "Setting up minimal frontend..."

# Create directory structure
sudo mkdir -p /opt/ClassServer/frontend/src/components
sudo mkdir -p /opt/ClassServer/frontend/public

# Create minimal package.json
sudo tee /opt/ClassServer/frontend/package.json > /dev/null << 'EOF'
{
  "name": "classserver-frontend",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.1",
    "vite": "^5.0.8"
  }
}
EOF

# Create minimal vite.config.js
sudo tee /opt/ClassServer/frontend/vite.config.js > /dev/null << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()]
});
EOF

# Create minimal index.html
sudo tee /opt/ClassServer/frontend/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>ClassServer</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

# Create minimal main.jsx
sudo tee /opt/ClassServer/frontend/src/main.jsx > /dev/null << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# Create minimal App.jsx
sudo tee /opt/ClassServer/frontend/src/App.jsx > /dev/null << 'EOF'
import React from 'react';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>ClassServer</h1>
        <p>Welcome to ClassServer</p>
      </header>
    </div>
  );
}

export default App;
EOF

# Install dependencies and build
cd /opt/ClassServer/frontend
sudo npm install
sudo npm run build

# Set permissions
sudo chown -R www-data:www-data /opt/ClassServer/frontend/dist

echo "Minimal frontend setup completed!" 