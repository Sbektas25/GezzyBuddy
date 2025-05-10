const mongoose = require('mongoose');

const packageSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Paket adı gereklidir'],
    trim: true
  },
  type: {
    type: String,
    required: [true, 'Paket tipi gereklidir'],
    enum: ['Plaj & Deniz', 'Kültürel & Tarihi']
  },
  description: {
    type: String,
    required: [true, 'Paket açıklaması gereklidir']
  },
  price: {
    type: Number,
    required: [true, 'Fiyat gereklidir']
  },
  duration: {
    type: Number,
    required: [true, 'Süre gereklidir']
  },
  activities: [{
    name: String,
    description: String,
    duration: Number,
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
      },
      coordinates: {
        type: [Number],
        required: true
      }
    }
  }],
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Konum indeksi
packageSchema.index({ 'activities.location': '2dsphere' });

module.exports = mongoose.model('Package', packageSchema); 