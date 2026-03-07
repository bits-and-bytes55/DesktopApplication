import mongoose from 'mongoose';

const pumpSchema = new mongoose.Schema({
  wellId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Well',
    required: false,  // REMOVED required - frontend uses static well context
    index: true
  },

  type: {
    type: String,
    enum: ['Triplex', 'Duplex', 'Quintuplex', 'Hydraulic', 'Quadplex', ''],
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

  displacement: {       // bbl/stk (calculated)
    type: Number,
    default: 0
  },

  spm: {                // strokes per minute
    type: Number,
    default: 0
  },

  rate: {               // GPM (calculated)
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

// Remove unique constraint on wellId+rowNumber since wellId is now optional
pumpSchema.index({ rowNumber: 1 });

export default mongoose.model('Pump', pumpSchema);