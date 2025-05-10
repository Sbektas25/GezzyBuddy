const express = require('express');
const router = express.Router();
const Package = require('../models/Package');

// Tüm paketleri listele
router.get('/', async (req, res) => {
  try {
    const packages = await Package.find();
    res.json({
      success: true,
      count: packages.length,
      data: packages
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Paket detayı getir
router.get('/:id', async (req, res) => {
  try {
    const package = await Package.findById(req.params.id);
    if (!package) {
      return res.status(404).json({
        success: false,
        error: 'Paket bulunamadı'
      });
    }
    res.json({
      success: true,
      data: package
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Yeni paket oluştur
router.post('/', async (req, res) => {
  try {
    const package = await Package.create(req.body);
    res.status(201).json({
      success: true,
      data: package
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Paket güncelle
router.put('/:id', async (req, res) => {
  try {
    const package = await Package.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    if (!package) {
      return res.status(404).json({
        success: false,
        error: 'Paket bulunamadı'
      });
    }
    res.json({
      success: true,
      data: package
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Paket sil
router.delete('/:id', async (req, res) => {
  try {
    const package = await Package.findByIdAndDelete(req.params.id);
    if (!package) {
      return res.status(404).json({
        success: false,
        error: 'Paket bulunamadı'
      });
    }
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