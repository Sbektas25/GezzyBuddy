const express = require('express');
const cors = require('cors');
const path = require('path');
const dotenv = require('dotenv');

// Environment variables
const PORT = 3001;
const MONGODB_URI = 'mongodb://localhost:27017/gezzybuddy';
const JWT_SECRET = 'gezzybuddy-super-secret-key-2024';
const NODE_ENV = 'development';

console.log('Environment variables:', {
  PORT,
  MONGODB_URI,
  JWT_SECRET,
  NODE_ENV
});

const connectDB = require('./src/config/database');
const { protect } = require('./src/middleware/auth');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', require('./src/routes/auth'));
app.use('/api/packages', require('./src/routes/packages'));
app.use('/api/itineraries', protect, require('./src/routes/itineraries'));

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Sunucu hatası!'
  });
});

// MongoDB bağlantısı ve sunucuyu başlatma
connectDB().then(() => {
  // Mevcut sunucuyu kontrol et ve kapat
  const server = app.listen(PORT, () => {
    console.log(`Sunucu ${PORT} portunda çalışıyor`);
  });

  server.on('error', (error) => {
    if (error.code === 'EADDRINUSE') {
      console.log('Port kullanımda, sunucu kapatılıyor...');
      server.close();
      process.exit(1);
    }
  });
}); 