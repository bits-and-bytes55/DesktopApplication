import mongoose from 'mongoose';

const pumpSchema = new mongoose.Schema({
  wellId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Well',
    required: true,
    index: true
  },
  type: {
    type: String,
    enum: ['Triplex', 'Duplex', 'Quintuplex', 'Hydraulic', ''],
    default: ''
  },
  model: {
    type: String,
    default: ''
  },
  linerId: {
    type: String,
    default: ''
  },
  rodOd: {
    type: String,
    default: ''
  },
  strokeLength: {
    type: String,
    default: ''
  },
  efficiency: {
    type: String,
    default: ''
  },
  displacement: {
    type: String,
    default: ''
  },
  maxPumpP: {
    type: String,
    default: ''
  },
  maxHp: {
    type: String,
    default: ''
  },
  surfaceLen: {
    type: String,
    default: ''
  },
  surfaceId: {
    type: String,
    default: ''
  },
  rowNumber: {
    type: Number,
    required: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  updatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true
});

// Compound index to ensure unique row numbers per well
pumpSchema.index({ wellId: 1, rowNumber: 1 }, { unique: true });

const Pump = mongoose.model('Pump', pumpSchema);

export default Pump;