const express = require('express');
const router = express.Router();
const Appointment = require('../models/Appointment');

// Emergency SOS Endpoint
router.post('/', async (req, res) => {
  try {
    const { patientName, timestamp } = req.body;

    // We hardcode the department to 'Emergency Room (ER)' and set type to 'emergency' 
    // to flag it as high priority in the dashboard.
    const emergencyTicket = new Appointment({
      patientName: patientName || 'Emergency Patient (Unknown)',
      department: 'Emergency Room (ER)',
      date: timestamp ? timestamp.split('T')[0] : undefined,
      type: 'emergency', // This acts as the crucial flag!
      status: 'waiting',
      // Provide some fallback mock data since we skip normal flow
      doctor: 'Emergency Doctor',
      hospital: 'Nearest Hospital',
      tokenNumber: Math.floor(Math.random() * 900) + 100 
    });

    await emergencyTicket.save();

    // If using Socket.io to emit an event
    const io = req.app.get('io');
    if (io) {
      io.emit('emergencyAlert', emergencyTicket);
      // We also emit to the queue update to make sure tables refresh
      io.emit('queueUpdate', {}); 
    }

    res.status(200).json({ message: "Emergency logged successfully", ticket: emergencyTicket });
  } catch (error) {
    console.error("SOS Error:", error);
    res.status(500).json({ error: "Failed to log emergency" });
  }
});

module.exports = router;
