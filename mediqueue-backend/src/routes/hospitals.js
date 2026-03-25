const router = require('express').Router();
const Hospital = require('../models/Hospital');
const authMiddleware = require('../middleware/auth');

// Create hospital (admin only)
router.post('/', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const { name, address, departments } = req.body;

    const hospital = new Hospital({ name, address, departments });
    await hospital.save();

    res.status(201).json(hospital);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get all hospitals
router.get('/', async (req, res) => {
  try {
    const hospitals = await Hospital.find();
    res.json(hospitals);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get departments of a hospital
router.get('/:id/departments', async (req, res) => {
  try {
    const hospital = await Hospital.findById(req.params.id);
    if (!hospital) return res.status(404).json({ message: 'Hospital not found' });

    res.json({ departments: hospital.departments });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;