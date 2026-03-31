import mongoose from "mongoose";

const mudLossStorageSchema = new mongoose.Schema(
  {
    wellId: {
      type: String,
      required: true,
      index: true,
    },
    storage: {
      type: String,
      required: true,
      trim: true,
    },
    dump: {
      type: Number,
      default: 0,
    },
    evaporation: {
      type: Number,
      default: 0,
    },
    pitCleaning: {
      type: Number,
      default: 0,
    },
    totalLoss: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

export default mongoose.model("MudLossStorage", mudLossStorageSchema);