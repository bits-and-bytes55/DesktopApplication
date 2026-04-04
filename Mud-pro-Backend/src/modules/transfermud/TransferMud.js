import mongoose from "mongoose";

const transferItemSchema = new mongoose.Schema({
  pitName: {
    type: String,
    required: true,
  },
  volume: {
    type: Number,
    required: true,
    default: 0,
  },
});

const transferMudSchema = new mongoose.Schema(
  {
    wellId: {
      type: String,
      required: true,
      index: true,
    },
    from: {
      type: String,
      required: true,
    },
    transfers: [transferItemSchema],
    totalTransferVol: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

export default mongoose.model("TransferMud", transferMudSchema);
