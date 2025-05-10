const express = require('express');
const router = express.Router();
const Itinerary = require('../models/Itinerary');

// Kullanıcının tüm seyahat planlarını getir
router.get('/my-plans', async (req, res) => {
  try {
    const itineraries = await Itinerary.find({ user: req.user.id })
      .populate('package')
      .sort('-createdAt');
    
    res.json({
      success: true,
      count: itineraries.length,
      data: itineraries
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Seyahat planı detayı getir
router.get('/:id', async (req, res) => {
  try {
    const itinerary = await Itinerary.findById(req.params.id)
      .populate('package')
      .populate('user', 'name email');
    
    if (!itinerary) {
      return res.status(404).json({
        success: false,
        error: 'Seyahat planı bulunamadı'
      });
    }

    // Kullanıcı kontrolü
    if (itinerary.user._id.toString() !== req.user.id) {
      return res.status(401).json({
        success: false,
        error: 'Bu seyahat planına erişim izniniz yok'
      });
    }

    res.json({
      success: true,
      data: itinerary
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Yeni seyahat planı oluştur
router.post('/', async (req, res) => {
  try {
    req.body.user = req.user.id;
    const itinerary = await Itinerary.create(req.body);
    
    res.status(201).json({
      success: true,
      data: itinerary
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Seyahat planı güncelle
router.put('/:id', async (req, res) => {
  try {
    let itinerary = await Itinerary.findById(req.params.id);
    
    if (!itinerary) {
      return res.status(404).json({
        success: false,
        error: 'Seyahat planı bulunamadı'
      });
    }

    // Kullanıcı kontrolü
    if (itinerary.user.toString() !== req.user.id) {
      return res.status(401).json({
        success: false,
        error: 'Bu seyahat planını güncelleme izniniz yok'
      });
    }

    itinerary = await Itinerary.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      data: itinerary
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Seyahat planı sil
router.delete('/:id', async (req, res) => {
  try {
    const itinerary = await Itinerary.findById(req.params.id);
    
    if (!itinerary) {
      return res.status(404).json({
        success: false,
        error: 'Seyahat planı bulunamadı'
      });
    }

    // Kullanıcı kontrolü
    if (itinerary.user.toString() !== req.user.id) {
      return res.status(401).json({
        success: false,
        error: 'Bu seyahat planını silme izniniz yok'
      });
    }

    await itinerary.deleteOne();

    res.json({
      success: true,
      data: {}
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router; 