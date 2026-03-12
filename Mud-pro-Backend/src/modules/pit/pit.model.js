import mongoose from 'mongoose';

const pitSchema = new mongoose.Schema({
  pitName: {
    type: String,
    required: true,
    trim: true
  },
  capacity: {
    type: Number,
    required: true,
    min: 0
  },
  initialActive: {
    type: Boolean,
    default: false
  },
  // wellId: {
  //   type: String,
  //   required: true,
  //   index: true
  // },
  reportId: {
    type: String,
    index: true
  },
  isLocked: {
    type: Boolean,
    default: false
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
pitSchema.index({pitName: 1 });
pitSchema.index({initialActive: 1 });

// ✅ FIXED: Updated pre-save middleware for Mongoose v7+
pitSchema.pre('save', async function() {
  this.updatedAt = Date.now();
});

// ✅ FIXED: Add pre-update middleware for update operations
pitSchema.pre('findOneAndUpdate', async function() {
  this.set({ updatedAt: Date.now() });
});

pitSchema.pre('updateMany', async function() {
  this.set({ updatedAt: Date.now() });
});

pitSchema.pre('bulkWrite', async function() {
  const ops = this._bulkWriteOps;
  ops.forEach(op => {
    if (op.updateOne || op.updateMany) {
      const updateOp = op.updateOne || op.updateMany;
      if (updateOp.update && updateOp.update.$set) {
        updateOp.update.$set.updatedAt = Date.now();
      } else {
        updateOp.update = { ...updateOp.update, $set: { updatedAt: Date.now() } };
      }
    }
  });
});

const Pit = mongoose.model('Pit', pitSchema);

export default Pit;