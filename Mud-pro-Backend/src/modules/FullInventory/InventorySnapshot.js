import mongoose from "mongoose";

const inventorySnapshotSchema = new mongoose.Schema(
  {
    category: {
      type: String,   // Product / Premixed Mud / Engineering
      default: "",
    },

    itemName: {
      type: String,
      default: "",
    },

    price: {
      type: Number,
      default: 0,
    },

    // 🔹 Cumulative Section
    cumulativeRec: {
      type: Number,
      default: 0,
    },

    cumulativeRet: {
      type: Number,
      default: 0,
    },

    cumulativeUsed: {
      type: Number,
      default: 0,
    },

    // 🔹 Daily Movement
    initial: {
      type: Number,
      default: 0,
    },

    rec: {
      type: Number,
      default: 0,
    },

    ret: {
      type: Number,
      default: 0,
    },

    adj: {
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

    // 🔹 Financial
    subtotal: {
      type: Number,
      default: 0,
    },

    costDollar: {
      type: Number,
      default: 0,
    },

    costPercent: {
      type: Number,
      default: 0,
    },

    totalDollar: {
      type: Number,
      default: 0,
    },

    totalPercent: {
      type: Number,
      default: 0,
    },

    // Date based snapshot
    reportDate: {
      type: Date,
      default: Date.now,
    }

  },
  { timestamps: true }
);

export default mongoose.model("InventorySnapshot", inventorySnapshotSchema);
