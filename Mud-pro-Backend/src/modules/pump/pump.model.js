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

  linerId: {            // inches
    type: Number,
    default: 0
  },

  rodOd: {
    type: Number,
    default: 0
  },

  strokeLength: {       // inches
    type: Number,
    default: 0
  },

  efficiency: {         // %
    type: Number,
    default: 0
  },

  displacement: {       // bbl/stk
    type: Number,
    default: 0
  },

  spm: {                // strokes per minute
    type: Number,
    default: 0
  },

  rate: {               // GPM
    type: Number,
    default: 0
  },

  maxPumpP: {
    type: Number,
    default: 0
  },

  maxHp: {
    type: Number,
    default: 0
  },

  surfaceLen: {
    type: Number,
    default: 0
  },

  surfaceId: {
    type: Number,
    default: 0
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

pumpSchema.index({ wellId: 1, rowNumber: 1 }, { unique: true });

export default mongoose.model('Pump', pumpSchema);