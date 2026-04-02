const express = require('express');
const router = express.Router();
const Appointment = require('../models/Appointment');

router.post('/', async (req, res) => {
  try {
    const { doctor, hospital, department } = req.body;

    const tokenNumber = Math.floor(Math.random() * 1000);

    const appointment = new Appointment({
      doctor,
      hospital,
      department,
      tokenNumber,
      status: "waiting",
    });

    await appointment.save();

    return res.status(201).json(appointment);

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;