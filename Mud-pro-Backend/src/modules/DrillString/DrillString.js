import mongoose from "mongoose";

const drillStringSchema = new mongoose.Schema(
  {
    wellId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Well",
      required: false,
      index: true,
      default: null,
    },

    reportId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Report",
      required: false,
      index: true,
      default: null,
    },

    reportNo: {
      type: String,
      trim: true,
      default: "",
    },

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
    },

    sortOrder: {
      type: Number,
      default: 0,
      index: true,
    },
  },
  { timestamps: true }
);

drillStringSchema.index({ wellId: 1, reportId: 1, createdAt: 1 });

export default mongoose.model("DrillString", drillStringSchema);
