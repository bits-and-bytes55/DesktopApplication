import mongoose from "mongoose";

const otherVolAdditionSchema = new mongoose.Schema(
  {
    wellId: {
      type: String,
      required: true,
      index: true,
    },
    formation: {
      type: Number,
      default: 0,
    },
    cuttings: {
      type: Number,
      default: 0,
    },
    volumeNotFluid: {
      type: Number,
      default: 0,
    },
    totalVolume: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

export default mongoose.model("OtherVolAddition", otherVolAdditionSchema);