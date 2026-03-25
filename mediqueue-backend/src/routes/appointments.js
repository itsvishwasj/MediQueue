const router = require('express').Router();
const Appointment = require('../models/Appointment');
const Doctor = require('../models/Doctor');
const authMiddleware = require('../middleware/auth');

// Book appointment
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { doctorId, hospitalId, department, type } = req.body;

    const today = new Date().toISOString().split('T')[0];

    const doctor = await Doctor.findById(doctorId);
    if (!doctor) return res.status(404).json({ message: 'Doctor not found' });

    const existingCount = await Appointment.countDocuments({
      doctor: doctorId,
      date: today,
      status: { $in: ['waiting', 'serving'] }
    });

    const tokenNumber = existingCount + 1;

    let estimatedWaitTime;
    if (type === 'emergency') {
      const currentlyServing = await Appointment.findOne({
        doctor: doctorId,
        date: today,
        status: 'serving'
      });
      estimatedWaitTime = currentlyServing ? doctor.avgConsultationTime : 0;
    } else {
      estimatedWaitTime = existingCount * doctor.avgConsultationTime;
    }

    const appointment = new Appointment({
      patient: req.user.id,
      doctor: doctorId,
      hospital: hospitalId,
      department,
      tokenNumber,
      type: type || 'normal',
      date: today,
      estimatedWaitTime
    });

    await appointment.save();

    const populated = await Appointment.findById(appointment._id)
      .populate('patient', 'name phone')
      .populate('doctor', 'name department avgConsultationTime')
      .populate('hospital', 'name');

    // Emit only to clients in this doctor's queue room
    const io = req.app.get('io');
    io.to(`queue:${doctorId}`).emit(`queue:${doctorId}`, {
      type: 'NEW_APPOINTMENT',
      appointment: populated
    });

    res.status(201).json(populated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get my appointments (patient)
router.get('/my', authMiddleware, async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];

    const appointments = await Appointment.find({
      patient: req.user.id,
      date: today
    })
      .populate('doctor', 'name department')
      .populate('hospital', 'name')
      .sort({ tokenNumber: 1 });

    res.json(appointments);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get all appointments for a doctor today
router.get('/doctor/:doctorId', authMiddleware, async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];

    const appointments = await Appointment.find({
      doctor: req.params.doctorId,
      date: today,
      status: { $in: ['waiting', 'serving'] }
    })
      .populate('patient', 'name phone')
      .populate('doctor', 'name department')
      .sort([['type', -1], ['tokenNumber', 1]]);

    res.json(appointments);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;