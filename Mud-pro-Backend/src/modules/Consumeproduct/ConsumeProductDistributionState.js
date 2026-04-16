import mongoose from "mongoose";

const distributionRowSchema = new mongoose.Schema(
  {
    pitName: {
      type: String,
      default: "",
      trim: true,
    },
    volume: {
      type: Number,
      default: 0,
    },
  },
  { _id: false }
);

const consumeProductDistributionStateSchema = new mongoose.Schema(
  {
    wellId: {
      type: String,
      required: true,
      index: true,
      trim: true,
    },
    reportId: {
      type: String,
      default: "",
      index: true,
      trim: true,
    },
    inputMethod: {
      type: String,
      default: "Used",
      trim: true,
    },
    addWaterEnabled: {
      type: Boolean,
      default: false,
    },
    addWaterVolume: {
      type: Number,
      default: 0,
    },
    totalVolume: {
      type: Number,
      default: 0,
    },
    distributions: {
      type: [distributionRowSchema],
      default: [],
    },
  },
  { timestamps: true }
);

consumeProductDistributionStateSchema.index(
  { wellId: 1, reportId: 1 },
  { unique: true }
);

export default mongoose.model(
  "ConsumeProductDistributionState",
  consumeProductDistributionStateSchema
);
