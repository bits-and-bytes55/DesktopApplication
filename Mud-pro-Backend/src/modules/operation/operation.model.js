import mongoose from "mongoose";

const operationSchema = new mongoose.Schema(
  {
    description: {
      type: String,
      required: true,
      trim: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    sortOrder: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

operationSchema.index({ description: 1 }, { unique: true });

const Operation = mongoose.model("Operation", operationSchema);

export default Operation;