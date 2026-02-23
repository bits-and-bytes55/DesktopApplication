// models/ConsumeProduct.js
import mongoose from "mongoose";

const consumeProductSchema = new mongoose.Schema(
  {
    // ✅ FIX: ObjectId ref hata diya — ab product name (String) save hoga
    product: {
      type: String,
      default: "",
    },

    code: {
      type: String,
      default: "",
    },

    sg: {
      type: Number,
      default: null,
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
    },

    volumeBbl: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

export default mongoose.model("ConsumeProduct", consumeProductSchema);