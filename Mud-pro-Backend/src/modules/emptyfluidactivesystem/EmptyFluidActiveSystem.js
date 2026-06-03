import mongoose from "mongoose";

const emptyFluidActiveSystemSchema = new mongoose.Schema(
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
    actionType: {
      type: String,
      enum: ["Dump", "Transfer to Storage"],
      required: true,
    },
    pitName: {
      type: String,
      default: "",
      trim: true,
    },
    rowNumber: {
      type: Number,
      default: 0,
      index: true,
    },
    volume: {
      type: Number,
      required: true,
      default: 0,
    },
    totalVolume: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

export default mongoose.model("EmptyFluidActiveSystem", emptyFluidActiveSystemSchema);
