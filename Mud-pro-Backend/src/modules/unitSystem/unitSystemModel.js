import mongoose from "mongoose";

// ─── Single parameter unit entry ─────────────────────────────────────────────
const parameterUnitSchema = new mongoose.Schema(
  {
    number:    { type: String, required: true },  // "1", "2" ... "53"
    name:      { type: String, required: true },  // "Length", "Pipe diameter" ...
    unit:      { type: String, required: true },  // "ft", "m", "ppg" ...
  },
  { _id: false }
);

// ─── Unit System document ─────────────────────────────────────────────────────
const unitSystemSchema = new mongoose.Schema(
  {
    // Display name shown in the left panel list
    name: {
      type:     String,
      required: true,
      trim:     true,
    },

    // "us" | "si" — the base template this system was created from
    baseTemplate: {
      type:    String,
      enum:    ["us", "si"],
      default: "us",
    },

    // Ordered list of 53 parameter→unit mappings
    parameters: {
      type:    [parameterUnitSchema],
      default: [],
    },

    // Soft-ordering for the left panel list (drag-insert support)
    sortOrder: {
      type:    Number,
      default: 0,
    },
  },
  { timestamps: true }
);

export default mongoose.model("UnitSystem", unitSystemSchema);