import mongoose from 'mongoose';

const obmSchema = new mongoose.Schema({
  product: {
    type: String,
    required: true,
    trim: true
  },
  code: {
    type: String,
    required: true
  },
  sg: {
    type: String,
    required: true
  },
  conc: {
    type: String,
    required: true
  },
  unit: {
    type: String,
    default: '',
    trim: true
  },
  wellId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Well',
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for faster queries
obmSchema.index({ wellId: 1 });

const Obm = mongoose.model('Obm', obmSchema);

export default Obm;
