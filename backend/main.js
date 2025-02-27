const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { sequelize } = require('./src/models');

// Import routes
const authRoutes = require('./routes/auth');
const gamesRoutes = require('./routes/games');

const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Routes
app.use('/auth', authRoutes);
app.use('/games', gamesRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to ClassServer API' });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Start server
async function startServer() {
  try {
    // Test database connection
    await sequelize.authenticate();
    console.log('Database connection established successfully');
    
    // Start server
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Unable to connect to the database:', error);
  }
}

startServer(); 