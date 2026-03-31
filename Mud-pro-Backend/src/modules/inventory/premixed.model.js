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
    type: String,
    required: true,
    index: true
  }
}, {
  timestamps: true
});

premixedSchema.index({ wellId: 1 });

const Premixed = mongoose.model('Premixed', premixedSchema);

export default Premixed;