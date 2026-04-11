const mongoose = require('mongoose');

const hospitalSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  address: {
    type: String,
    required: true
  },
  fullAddress: {
    type: String
  },
  location: {
    latitude: { type: Number },
    longitude: { type: Number }
  },
  departments: [{
    type: String,
    trim: true
  }]
}, { timestamps: true });

module.exports = mongoose.model('Hospital', hospitalSchema);
