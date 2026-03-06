// modules/Package.js

import mongoose from "mongoose";

const packageSchema = new mongoose.Schema(
  {
    packageName: {
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

    initial: {
      type: Number,
      default: 0,
    },

    adjust: {
      type: Number,
      default: 0,
    },

    used: {
      type: Number,
      default: 0,
    },

    final: {
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

export default mongoose.model("ConsumePackage", packageSchema);
