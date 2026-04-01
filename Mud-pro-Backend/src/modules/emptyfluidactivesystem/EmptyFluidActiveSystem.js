import mongoose from "mongoose";

const emptyFluidActiveSystemSchema = new mongoose.Schema(
  {
    wellId: {
      type: String,
      required: true,
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