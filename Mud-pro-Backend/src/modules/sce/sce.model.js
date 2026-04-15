import mongoose from 'mongoose';

const shakerSchema = new mongoose.Schema({
  wellId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'Well'
  },
  reportId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Report',
    required: false,
    index: true,
    default: null,
  },
  reportNo: {
    type: String,
    trim: true,
    default: '',
  },
  shaker: {
    type: String,
    required: true
  },
  model: {
    type: String,
    default: ''
  },
  screens: {
    type: String,
    default: ''
  },
  plot: {
    type: Boolean,
    default: false
  },
  screen1: {
    type: String,
    default: ''
  },
  screen2: {
    type: String,
    default: ''
  },
  screen3: {
    type: String,
    default: ''
  },
  screen4: {
    type: String,
    default: ''
  },
  screen5: {
    type: String,
    default: ''
  },
  screen6: {
    type: String,
    default: ''
  },
  screen7: {
    type: String,
    default: ''
  },
  screen8: {
    type: String,
    default: ''
  },
  time: {
    type: String,
    default: ''
  },
  oocWt: {
    type: String,
    default: ''
  }
}, {
  timestamps: true
});

const otherSceSchema = new mongoose.Schema({
  wellId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'Well'
  },
  reportId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Report',
    required: false,
    index: true,
    default: null,
  },
  reportNo: {
    type: String,
    trim: true,
    default: '',
  },
  type: {
    type: String,
    required: true
  },
  model1: {
    type: String,
    default: ''
  },
  model2: {
    type: String,
    default: ''
  },
  model3: {
    type: String,
    default: ''
  },
  plot: {
    type: Boolean,
    default: false
  },
  uf: {
    type: String,
    default: ''
  },
  of: {
    type: String,
    default: ''
  },
  time: {
    type: String,
    default: ''
  },
  oocWt: {
    type: String,
    default: ''
  }
}, {
  timestamps: true
});

// Indexes for faster queries
shakerSchema.index({ wellId: 1, reportId: 1, shaker: 1 });
otherSceSchema.index({ wellId: 1, reportId: 1, type: 1 });

export const Shaker = mongoose.model('Shaker', shakerSchema);
export const OtherSce = mongoose.model('OtherSce', otherSceSchema);
