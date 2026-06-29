import mongoose from "mongoose";

const otherVolAdditionSchema = new mongoose.Schema(
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
    operationInstanceKey: {
      type: String,
      default: "",
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
    activePitsBaselineTotal: {
      type: Number,
      default: null,
    },
  },
  { timestamps: true }
);

export default mongoose.model("OtherVolAddition", otherVolAdditionSchema);
