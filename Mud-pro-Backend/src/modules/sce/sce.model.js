import mongoose from 'mongoose';

const shakerSchema = new mongoose.Schema({
  wellId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'Well'
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
  }
}, {
  timestamps: true
});

// Indexes for faster queries
shakerSchema.index({ wellId: 1 });
otherSceSchema.index({ wellId: 1 });

export const Shaker = mongoose.model('Shaker', shakerSchema);
export const OtherSce = mongoose.model('OtherSce', otherSceSchema);