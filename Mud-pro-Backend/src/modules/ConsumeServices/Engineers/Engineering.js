import mongoose from "mongoose";

const engineeringSchema = new mongoose.Schema(
  {
    wellId: {
      type: String,
      default: "",
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

    engineeringName: {
      type: String,
      default: "",
    },

    code: {
      type: String,
      default: "",
    },

    unit: {
      type: String,
      default: "",
    },

    price: {
      type: Number,
      default: 0,
    },

    usage: {
      type: Number,
      default: 0,
    },

    cost: {
      type: Number,
      default: 0,
    }
  },
  { timestamps: true }
);

export default mongoose.model("ConsumeEngineering", engineeringSchema);
