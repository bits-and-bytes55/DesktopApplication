import mongoose from "mongoose";

const returnLostMudSchema = new mongoose.Schema(
  {
    wellId: {
      type: String,
      required: true,
      index: true,
    },
    premixedMud: {
      type: String,
      required: true,
      default: "",
    },
    from: {
      type: String,
      required: true,
      default: "",
    },
    to: {
      type: String,
      required: true,
      default: "",
    },
    volReturned: {
      type: Number,
      default: 0,
    },
    mw: {
      type: Number,
      default: 0,
    },
    mudType: {
      type: String,
      default: "",
    },
    bol: {
      type: Number,
      default: 0,
    },
    volLost: {
      type: Number,
      default: 0,
    },
    costOfLostPreTax: {
      type: Number,
      default: 0,
    },
    leased: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

export default mongoose.model("ReturnLostMud", returnLostMudSchema);