import mongoose from 'mongoose';

const premixedSchema = new mongoose.Schema({
  description: {
    type: String,
    required: true,
    trim: true
  },
  mw: {
    type: String,
    required: true
  },
  leasingFee: {
    type: String,
    required: true
  },
  mudType: {
    type: String,
    required: true
  },
  tax: {
    type: Boolean,
    default: false
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
premixedSchema.index({ wellId: 1 });

const Premixed = mongoose.model('Premixed', premixedSchema);

export default Premixed;