const mongoose = require('mongoose');

const itinerarySchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  package: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Package',
    required: true
  },
  startDate: {
    type: Date,
    required: [true, 'Başlangıç tarihi gereklidir']
  },
  endDate: {
    type: Date,
    required: [true, 'Bitiş tarihi gereklidir']
  },
  status: {
    type: String,
    enum: ['planning', 'confirmed', 'completed', 'cancelled'],
    default: 'planning'
  },
  activities: [{
    activity: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Package.activities'
    },
    scheduledTime: Date,
    notes: String
  }],
  totalPrice: {
    type: Number,
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Itinerary', itinerarySchema); 