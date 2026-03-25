const mongoose = require('mongoose');

const hospitalProfileSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  hospital: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Hospital',
    required: true
  }
}, { timestamps: true });

module.exports = mongoose.model('HospitalProfile', hospitalProfileSchema);