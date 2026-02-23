import mongoose from "mongoose";

const drillStringSchema = new mongoose.Schema(
  {
    description: {
      type: String,
      required: true
    },

    od: {              // Outer Diameter
      type: Number,
      default: 0
    },

    weightPpf: {      // Weight per foot
      type: Number,
      default: 0
    },

    id: {             // Inner Diameter
      type: Number,
      default: 0
    },

    grade: {
      type: String,
      default: ""
    },

    length: {         // Individual length
      type: Number,
      default: 0
    }
  },
  { timestamps: true }
);

export default mongoose.model("DrillString", drillStringSchema);