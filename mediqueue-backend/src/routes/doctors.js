const router = require('express').Router();
const Doctor = require('../models/Doctor');

// POST /api/doctors - Add a doctor
router.post('/', async (req, res) => {
  try {
    const { name, hospital, department, avgConsultationTime } = req.body;
    const doctor = new Doctor({
      name, hospital, department,
      avgConsultationTime: avgConsultationTime || 10
    });
    await doctor.save();
    res.status(201).json(doctor);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/doctors - Get doctors
router.get('/', async (req, res) => {
  try {
    const { hospitalId, hospital, department } = req.query;
    const filter = {};
    // Support both hospitalId and hospital query keys for compatibility.
    if (hospitalId || hospital) filter.hospital = hospitalId || hospital;
    if (department) filter.department = department;

    const doctors = await Doctor.find(filter).populate('hospital', 'name');
    res.json(doctors);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/doctors/hospital/:hospitalId - Compatibility endpoint
router.get('/hospital/:hospitalId', async (req, res) => {
  try {
    const doctors = await Doctor.find({ hospital: req.params.hospitalId }).populate('hospital', 'name');
    res.json(doctors);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/doctors/:id - Get single doctor
router.get('/:id', async (req, res) => {
  try {
    const doctor = await Doctor.findById(req.params.id).populate('hospital', 'name');
    if (!doctor) return res.status(404).json({ message: 'Doctor not found' });
    res.json(doctor);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/doctors/:id - Edit a doctor
router.put('/:id', async (req, res) => {
  try {
    const { name, department, avgConsultationTime } = req.body;
    const update = {};
    if (name) update.name = name;
    if (department) update.department = department;
    if (avgConsultationTime) update.avgConsultationTime = parseInt(avgConsultationTime);
 
    const doctor = await Doctor.findByIdAndUpdate(
      req.params.id, { $set: update }, { new: true }
    ).populate('hospital', 'name');
 
    if (!doctor) return res.status(404).json({ message: 'Doctor not found' });
    res.json(doctor);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
 
// DELETE /api/doctors/:id - Remove a doctor
router.delete('/:id', async (req, res) => {
  try {
    const doctor = await Doctor.findByIdAndDelete(req.params.id);
    if (!doctor) return res.status(404).json({ message: 'Doctor not found' });
    res.json({ message: 'Doctor deleted', id: req.params.id });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
