const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Hospital = require('../models/Hospital');
const HospitalProfile = require('../models/HospitalProfile');
const { extractCoordinatesFromGoogleMapsLink } = require('../utils/googleMaps');

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, phone, role } = req.body;

    // Check if user already exists
    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ message: 'Email already registered' });

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    const user = new User({
      name,
      email,
      password: hashedPassword,
      phone,
      role: role || 'patient'
    });

    await user.save();

    // Generate token
    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role
      }
    });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: 'Invalid credentials' });

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ message: 'Invalid credentials' });

    // Generate token
    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role
      }
    });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Hospital registration
router.post('/register/hospital', async (req, res) => {
  try {
    let {
      // Account details
      email,
      password,
      phone,
      // Hospital details
      hospitalName,
      googleMapsLink,
      address,
      departments
    } = req.body;

    if (email) email = email.trim().toLowerCase();

    // Check if email already exists
    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    const { mapsLink, location } = await extractCoordinatesFromGoogleMapsLink(googleMapsLink || address);
    if (!mapsLink) {
      return res.status(400).json({ message: 'Google Maps link is required' });
    }
    if (!location) {
      return res.status(400).json({ message: 'Enter a valid Google Maps link with coordinates' });
    }

    // Create user account with hospital role
    const user = new User({
      name: hospitalName,
      email,
      password: hashedPassword,
      phone,
      role: 'hospital'
    });
    await user.save();

    // Create hospital document
    const hospital = new Hospital({
      name: hospitalName,
      address: mapsLink,
      fullAddress: mapsLink,
      location: location || undefined,
      departments: departments || []
    });
    await hospital.save();

    // Link user to hospital
    const profile = new HospitalProfile({
      user: user._id,
      hospital: hospital._id
    });
    await profile.save();

    // Generate token
    const token = jwt.sign(
      { id: user._id, role: user.role, hospitalId: hospital._id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        hospitalId: hospital._id
      }
    });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Hospital login
router.post('/login/hospital', async (req, res) => {
  try {
    let { email, password } = req.body;
    if (email) email = email.trim().toLowerCase();

    const user = await User.findOne({ email });
    if (!user || user.role !== 'hospital') {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // Get hospital profile
    const profile = await HospitalProfile.findOne({ user: user._id });
    if (!profile) {
      return res.status(400).json({ message: 'Hospital profile not found' });
    }

    const token = jwt.sign(
      { id: user._id, role: user.role, hospitalId: profile.hospital },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        hospitalId: profile.hospital
      }
    });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
