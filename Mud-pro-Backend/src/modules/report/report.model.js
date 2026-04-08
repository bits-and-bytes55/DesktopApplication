import mongoose from "mongoose";

const reportSchema = new mongoose.Schema(
  {
    wellId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Well",
      required: true,
      index: true,
    },
    reportNo: {
      type: String,
      required: true,
      trim: true,
    },
    userReportNo: {
      type: String,
      default: "",
      trim: true,
    },
    reportDate: {
      type: String,
      default: "",
      trim: true,
    },
    title: {
      type: String,
      default: "",
      trim: true,
    },
    notes: {
      type: String,
      default: "",
      trim: true,
    },
  },
  { timestamps: true }
);

reportSchema.index({ wellId: 1, reportNo: 1 }, { unique: true });

const Report = mongoose.model("Report", reportSchema);

export default Report;
