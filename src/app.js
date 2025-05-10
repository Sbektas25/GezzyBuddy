const express = require('express');
const cors = require('cors');
const connectDB = require('./config/database');
const { protect } = require('./middleware/auth');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/packages', require('./routes/packages'));
app.use('/api/itineraries', protect, require('./routes/itineraries'));

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Sunucu hatası!'
  });
});

const PORT = process.env.PORT || 3000;

// MongoDB bağlantısı ve sunucuyu başlatma
connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`Sunucu ${PORT} portunda çalışıyor`);
  });
}); 