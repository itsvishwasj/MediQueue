const router = require('express').Router();
const Hospital = require('../models/Hospital');
const authMiddleware = require('../middleware/auth');
const QRCode = require('qrcode');
const Doctor = require('../models/Doctor');

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

// Generate booking QR for a doctor (hospital prints this)
router.get('/qr/:doctorId', async (req, res) => {
  try {
    const doctor = await Doctor.findById(req.params.doctorId)
      .populate('hospital', 'name');

    if (!doctor) return res.status(404).json({ message: 'Doctor not found' });

    // This URL opens the booking page in the Flutter app or web
    const bookingUrl = `mediqueue://book?doctorId=${doctor._id}&hospitalId=${doctor.hospital._id}&department=${encodeURIComponent(doctor.department)}`;

    // Generate QR as base64 image
    const qrImage = await QRCode.toDataURL(bookingUrl, {
      width: 300,
      margin: 2,
      color: {
        dark: '#1a73e8',
        light: '#ffffff'
      }
    });

    res.json({
      doctorId: doctor._id,
      doctorName: doctor.name,
      department: doctor.department,
      hospitalName: doctor.hospital.name,
      bookingUrl,
      qrImage  // base64 PNG — use directly in <img src="...">
    });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;