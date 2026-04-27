import mongoose from 'mongoose';

const casingSchema = new mongoose.Schema({
  wellId: {
      type: String,
      required: true,
      index: true,
    },
  reportId: {
      type: String,
      default: '',
      index: true,
    },
  description: { type: String, default: '' },
  type: { type: String, default: '' },
  od: { type: String, default: '' },
  wt: { type: String, default: '' },
  id: { type: String, default: '' },
  top: { type: String, default: '' },
  shoe: { type: String, default: '' },
  bit: { type: String, default: '' },
  toc: { type: String, default: '' },
  sortOrder: { type: Number, default: 0, index: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, {
  timestamps: true
});

export default mongoose.model('Casing', casingSchema);
