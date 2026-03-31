import mongoose from "mongoose";

const mudLossSchema = new mongoose.Schema(
  {
    wellId: {
      type: String,
      required: true,
      index: true,
    },
    cuttingsRetention: {
      type: Number,
      default: 0,
    },
    seepage: {
      type: Number,
      default: 0,
    },
    dump: {
      type: Number,
      default: 0,
    },
    shakers: {
      type: Number,
      default: 0,
    },
    centrifuge: {
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
    formation: {
      type: Number,
      default: 0,
    },
    abandonInHole: {
      type: Number,
      default: 0,
    },
    leftBehindCasing: {
      type: Number,
      default: 0,
    },
    tripping: {
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

export default mongoose.model("MudLoss", mudLossSchema);