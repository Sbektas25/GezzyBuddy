const express = require('express');
const router = express.Router();
const User = require('../models/User');
const jwt = require('jsonwebtoken');

// Kayıt olma
router.post('/register', async (req, res) => {
  try {
    console.log('Register request received:', req.body);
    const { email, password, name } = req.body;

    // Validation
    if (!email || !password || !name) {
      console.log('Missing required fields');
      return res.status(400).json({
        success: false,
        error: 'Lütfen tüm alanları doldurun'
      });
    }

    // Email validation
    if (!email.includes('@')) {
      console.log('Invalid email format');
      return res.status(400).json({
        success: false,
        error: 'Geçerli bir email adresi girin'
      });
    }

    // Password validation
    if (password.length < 6) {
      console.log('Password too short');
      return res.status(400).json({
        success: false,
        error: 'Şifre en az 6 karakter olmalıdır'
      });
    }

    // Email kontrolü
    console.log('Checking if email exists:', email);
    const userExists = await User.findOne({ email });
    if (userExists) {
      console.log('Email already exists');
      return res.status(400).json({
        success: false,
        error: 'Bu email adresi zaten kullanılıyor'
      });
    }

    // Yeni kullanıcı oluşturma
    console.log('Creating new user');
    const user = await User.create({
      name,
      email,
      password
    });

    console.log('User created:', user._id);

    // Token oluşturma
    const token = jwt.sign(
      { id: user._id },
      process.env.JWT_SECRET || 'gezzybuddy-super-secret-key-2024',
      { expiresIn: '30d' }
    );

    console.log('Token created');

    res.status(201).json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Kayıt işlemi başarısız oldu'
    });
  }
});

// Giriş yapma
router.post('/login', async (req, res) => {
  try {
    console.log('Login request received:', req.body);
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Lütfen email ve şifrenizi girin'
      });
    }

    // Kullanıcı kontrolü
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Geçersiz email veya şifre'
      });
    }

    // Şifre kontrolü
    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        error: 'Geçersiz email veya şifre'
      });
    }

    // Token oluşturma
    const token = jwt.sign(
      { id: user._id },
      process.env.JWT_SECRET || 'gezzybuddy-super-secret-key-2024',
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: 'Giriş yapılamadı'
    });
  }
});

module.exports = router; 