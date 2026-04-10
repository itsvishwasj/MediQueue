const router = require('express').Router();
const Hospital = require('../models/Hospital');
const QRCode = require('qrcode');
const Doctor = require('../models/Doctor');

// POST /api/hospitals
router.post('/', async (req, res) => {
  try {
    const { name, address, departments } = req.body;
    const hospital = new Hospital({ name, address, departments });
    await hospital.save();
    res.status(201).json(hospital);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/hospitals
router.get('/', async (req, res) => {
  try {
    const hospitals = await Hospital.find();
    res.json(hospitals);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/hospitals/:id - Get single hospital details
router.get('/:id', async (req, res) => {
  try {
    const hospital = await Hospital.findById(req.params.id);
    if (!hospital) return res.status(404).json({ message: 'Hospital not found' });
    res.json(hospital);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/hospitals/:id/departments - Get departments for a hospital
router.get('/:id/departments', async (req, res) => {
  try {
    const hospital = await Hospital.findById(req.params.id);
    if (!hospital) return res.status(404).json({ message: 'Hospital not found' });
    res.json({ departments: hospital.departments });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/hospitals/:id - Edit hospital profile
router.put('/:id', async (req, res) => {
  try {
    const { name, address, departments } = req.body;
    const update = {};
    if (name) update.name = name;
    if (address) update.address = address;
    if (departments) update.departments = Array.isArray(departments) 
        ? departments : departments.split(',').map(d => d.trim()).filter(Boolean);
 
    const hospital = await Hospital.findByIdAndUpdate(
      req.params.id, { $set: update }, { new: true }
    );
    if (!hospital) return res.status(404).json({ message: 'Hospital not found' });
    res.json(hospital);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
 
// DELETE /api/hospitals/:id - Cascade delete hospital & its doctors
router.delete('/:id', async (req, res) => {
  try {
    const hospital = await Hospital.findByIdAndDelete(req.params.id);
    if (!hospital) return res.status(404).json({ message: 'Hospital not found' });
    await Doctor.deleteMany({ hospital: req.params.id }); // Cascade delete
    res.json({ message: 'Hospital deleted', id: req.params.id });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
 
// GET /api/hospitals/:id/reception-qr - Gen Hospital-level QR
router.get('/:id/reception-qr', async (req, res) => {
  try {
    const hospital = await Hospital.findById(req.params.id);
    if (!hospital) return res.status(404).json({ message: 'Hospital not found' });
 
    const payload = `mediqueue://hospital?id=${req.params.id}`;
    const qrDataUrl = await QRCode.toDataURL(payload, {
      width: 400, margin: 2, color: { dark: '#0F172A', light: '#FFFFFF' }
    });
 
    res.json({
      hospitalId: req.params.id,
      hospitalName: hospital.name,
      payload,
      qrDataUrl
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/hospitals/:id/cabin-qr/:doctorId - Generate doctor cabin QR
router.get('/:id/cabin-qr/:doctorId', async (req, res) => {
  try {
    const hospital = await Hospital.findById(req.params.id);
    if (!hospital) return res.status(404).json({ message: 'Hospital not found' });

    const doctor = await Doctor.findById(req.params.doctorId);
    if (!doctor) return res.status(404).json({ message: 'Doctor not found' });

    const payload = `mediqueue://book?doctorId=${req.params.doctorId}&hospitalId=${req.params.id}`;
    const qrDataUrl = await QRCode.toDataURL(payload, {
      width: 400, margin: 2, color: { dark: '#0F172A', light: '#FFFFFF' }
    });

    res.json({
      hospitalId: req.params.id,
      doctorId: req.params.doctorId,
      payload,
      qrDataUrl
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
