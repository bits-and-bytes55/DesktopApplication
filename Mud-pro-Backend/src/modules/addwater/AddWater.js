import mongoose from "mongoose";

const addWaterSchema = new mongoose.Schema(
  {
    wellId: {
      type: String,
      required: true,
      index: true,
    },
    reportId: {
      type: String,
      default: "",
      index: true,
    },
    to: {
      type: String,
      required: true,
      trim: true,
    },
    volume: {
      type: Number,
      required: true,
      default: 0,
    },
  },
  { timestamps: true }
);

export default mongoose.model("AddWater", addWaterSchema);
