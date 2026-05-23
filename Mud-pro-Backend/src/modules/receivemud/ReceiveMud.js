import mongoose from "mongoose";

const receiveMudSchema = new mongoose.Schema(
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
    bolNo: {
      type: String,
      default: "",
    },
    premixedMud: {
      type: String,
      default: "",
    },
    mw: {
      type: Number,
      default: 0,
    },
    mudType: {
      type: String,
      default: "",
    },
    leasingFee: {
      type: Number,
      default: 0,
    },
    from: {
      type: String,
      default: "",
    },
    to: {
      type: String,
      required: true,
    },
    volume: {
      type: Number,

      default: 0,
    },
    leased: {
      type: Boolean,
      default: false,
    },
    lossVolume: {
      type: Number,
      default: 0,
    },
    netVolume: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

export default mongoose.model("ReceiveMud", receiveMudSchema);
