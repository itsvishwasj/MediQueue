const router = require('express').Router();
const Appointment = require('../models/Appointment');
const Doctor = require('../models/Doctor');
const authMiddleware = require('../middleware/auth');

// Get queue status for a doctor
router.get('/:doctorId', async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const { doctorId } = req.params;

    const doctor = await Doctor.findById(doctorId);
    if (!doctor) return res.status(404).json({ message: 'Doctor not found' });

    // Currently serving
    const serving = await Appointment.findOne({
      doctor: doctorId,
      date: today,
      status: 'serving'
    }).populate('patient', 'name');

    // Waiting list — emergency first, then by token number
    const waiting = await Appointment.find({
      doctor: doctorId,
      date: today,
      status: 'waiting'
    })
      .populate('patient', 'name phone')
      .sort([['type', -1], ['tokenNumber', 1]]);

    // Build response
    const queue = waiting.map((apt, index) => ({
      _id: apt._id,
      tokenNumber: apt.tokenNumber,
      patientName: apt.patient.name,
      patientPhone: apt.patient.phone,
      type: apt.type,
      position: index + 1,
      estimatedWaitTime: index * doctor.avgConsultationTime
    }));

    res.json({
      doctorId,
      doctorName: doctor.name,
      currentToken: serving ? serving.tokenNumber : null,
      currentPatient: serving ? serving.patient.name : null,
      waitingCount: waiting.length,
      queue
    });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});const router = require('express').Router();
const Appointment = require('../models/Appointment');
const Doctor = require('../models/Doctor');
const authMiddleware = require('../middleware/auth');

// Get queue status for a doctor
router.get('/:doctorId', async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const { doctorId } = req.params;

    const doctor = await Doctor.findById(doctorId);
    if (!doctor) return res.status(404).json({ message: 'Doctor not found' });

    const serving = await Appointment.findOne({
      doctor: doctorId,
      date: today,
      status: 'serving'
    }).populate('patient', 'name');

    const waiting = await Appointment.find({
      doctor: doctorId,
      date: today,
      status: 'waiting'
    })
      .populate('patient', 'name phone')
      .sort([['type', -1], ['tokenNumber', 1]]);

    const queue = waiting.map((apt, index) => ({
      _id: apt._id,
      tokenNumber: apt.tokenNumber,
      patientName: apt.patient.name,
      patientPhone: apt.patient.phone,
      type: apt.type,
      position: index + 1,
      estimatedWaitTime: index * doctor.avgConsultationTime
    }));

    res.json({
      doctorId,
      doctorName: doctor.name,
      currentToken: serving ? serving.tokenNumber : null,
      currentPatient: serving ? serving.patient.name : null,
      waitingCount: waiting.length,
      queue
    });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Next patient — admin only
router.post('/:doctorId/next', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const today = new Date().toISOString().split('T')[0];
    const { doctorId } = req.params;

    const doctor = await Doctor.findById(doctorId);
    if (!doctor) return res.status(404).json({ message: 'Doctor not found' });

    // Mark current as completed
    await Appointment.findOneAndUpdate(
      { doctor: doctorId, date: today, status: 'serving' },
      { status: 'completed' }
    );

    // Get next patient
    const nextAppointment = await Appointment.findOne({
      doctor: doctorId,
      date: today,
      status: 'waiting'
    })
      .populate('patient', 'name phone')
      .sort([['type', -1], ['tokenNumber', 1]]);

    const io = req.app.get('io');

    if (!nextAppointment) {
      io.to(`queue:${doctorId}`).emit(`queue:${doctorId}`, {
        type: 'QUEUE_EMPTY',
        message: 'No more patients in queue'
      });
      return res.json({ message: 'No more patients in queue' });
    }

    // Mark next as serving
    nextAppointment.status = 'serving';
    await nextAppointment.save();

    // Get updated waiting list
    const waiting = await Appointment.find({
      doctor: doctorId,
      date: today,
      status: 'waiting'
    })
      .populate('patient', 'name phone')
      .sort([['type', -1], ['tokenNumber', 1]]);

    const queue = waiting.map((apt, index) => ({
      _id: apt._id,
      tokenNumber: apt.tokenNumber,
      patientName: apt.patient.name,
      type: apt.type,
      position: index + 1,
      estimatedWaitTime: index * doctor.avgConsultationTime
    }));

    const queueUpdate = {
      type: 'NEXT_PATIENT',
      currentToken: nextAppointment.tokenNumber,
      currentPatient: nextAppointment.patient.name,
      waitingCount: waiting.length,
      queue
    };

    // Broadcast to room only
    io.to(`queue:${doctorId}`).emit(`queue:${doctorId}`, queueUpdate);

    res.json(queueUpdate);

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Cancel appointment
router.post('/:appointmentId/cancel', authMiddleware, async (req, res) => {
  try {
    const appointment = await Appointment.findById(req.params.appointmentId);
    if (!appointment) return res.status(404).json({ message: 'Appointment not found' });

    if (
      appointment.patient.toString() !== req.user.id &&
      req.user.role !== 'admin'
    ) {
      return res.status(403).json({ message: 'Access denied' });
    }

    appointment.status = 'cancelled';
    await appointment.save();

    const io = req.app.get('io');
    io.to(`queue:${appointment.doctor}`).emit(`queue:${appointment.doctor}`, {
      type: 'APPOINTMENT_CANCELLED',
      appointmentId: appointment._id
    });

    res.json({ message: 'Appointment cancelled' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;

// Next patient — admin only
router.post('/:doctorId/next', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const today = new Date().toISOString().split('T')[0];
    const { doctorId } = req.params;

    const doctor = await Doctor.findById(doctorId);
    if (!doctor) return res.status(404).json({ message: 'Doctor not found' });

    // Mark current serving appointment as completed
    await Appointment.findOneAndUpdate(
      { doctor: doctorId, date: today, status: 'serving' },
      { status: 'completed' }
    );

    // Get next patient — emergency first, then by token number
    const nextAppointment = await Appointment.findOne({
      doctor: doctorId,
      date: today,
      status: 'waiting'
    })
      .populate('patient', 'name phone')
      .sort([['type', -1], ['tokenNumber', 1]]);

    if (!nextAppointment) {
      // No more patients
      const io = req.app.get('io');
      io.emit(`queue:${doctorId}`, {
        type: 'QUEUE_EMPTY',
        message: 'No more patients in queue'
      });

      return res.json({ message: 'No more patients in queue' });
    }

    // Mark next patient as serving
    nextAppointment.status = 'serving';
    await nextAppointment.save();

    // Get updated full queue
    const waiting = await Appointment.find({
      doctor: doctorId,
      date: today,
      status: 'waiting'
    })
      .populate('patient', 'name phone')
      .sort([['type', -1], ['tokenNumber', 1]]);

    const queue = waiting.map((apt, index) => ({
      _id: apt._id,
      tokenNumber: apt.tokenNumber,
      patientName: apt.patient.name,
      type: apt.type,
      position: index + 1,
      estimatedWaitTime: index * doctor.avgConsultationTime
    }));

    const queueUpdate = {
      type: 'NEXT_PATIENT',
      currentToken: nextAppointment.tokenNumber,
      currentPatient: nextAppointment.patient.name,
      waitingCount: waiting.length,
      queue
    };

    // Broadcast to ALL clients watching this doctor's queue
    const io = req.app.get('io');
    io.emit(`queue:${doctorId}`, queueUpdate);

    res.json(queueUpdate);

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Cancel appointment
router.post('/:appointmentId/cancel', authMiddleware, async (req, res) => {
  try {
    const appointment = await Appointment.findById(req.params.appointmentId);
    if (!appointment) return res.status(404).json({ message: 'Appointment not found' });

    // Only the patient or admin can cancel
    if (
      appointment.patient.toString() !== req.user.id &&
      req.user.role !== 'admin'
    ) {
      return res.status(403).json({ message: 'Access denied' });
    }

    appointment.status = 'cancelled';
    await appointment.save();

    // Notify queue
    const io = req.app.get('io');
    io.emit(`queue:${appointment.doctor}`, {
      type: 'APPOINTMENT_CANCELLED',
      appointmentId: appointment._id
    });

    res.json({ message: 'Appointment cancelled' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;