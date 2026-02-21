import mongoose from "mongoose";

const inventorySnapshotSchema = new mongoose.Schema(
  {
    category: {
      type: String,
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

    // Movement
    used: {
      type: Number,
      default: 0,
    },

    final: {
      type: Number,
      default: 0,
    },

    // Financial
    subtotal: {
      type: Number,
      default: 0,
    },

    cost: {
      type: Number,
      default: 0,
    },

    total: {
      type: Number,
      default: 0,
    },

    reportDate: {
      type: Date,
      default: Date.now,
    }
  },
  { timestamps: true }
);

export default mongoose.model("InventorySnapshot", inventorySnapshotSchema);
