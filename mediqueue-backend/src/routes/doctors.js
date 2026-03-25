const router = require('express').Router();
const Doctor = require('../models/Doctor');
const authMiddleware = require('../middleware/auth');

// Add a doctor (admin only)
router.post('/', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const { name, hospital, department, avgConsultationTime } = req.body;

    const doctor = new Doctor({
      name,
      hospital,
      department,
      avgConsultationTime: avgConsultationTime || 10
    });

    await doctor.save();
    res.status(201).json(doctor);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get doctors by hospital and department
router.get('/', async (req, res) => {
  try {
    const { hospitalId, department } = req.query;

    const filter = {};
    if (hospitalId) filter.hospital = hospitalId;
    if (department) filter.department = department;

    const doctors = await Doctor.find(filter).populate('hospital', 'name');
    res.json(doctors);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get single doctor
router.get('/:id', async (req, res) => {
  try {
    const doctor = await Doctor.findById(req.params.id).populate('hospital', 'name');
    if (!doctor) return res.status(404).json({ message: 'Doctor not found' });
    res.json(doctor);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;