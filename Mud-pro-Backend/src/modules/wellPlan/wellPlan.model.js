import mongoose from "mongoose";

const planSummaryItemSchema = new mongoose.Schema(
  {
    type: { type: String, default: "", trim: true },
    amount: { type: String, default: "", trim: true },
    unit: { type: String, default: "", trim: true },
  },
  { _id: false }
);

const planRowSchema = new mongoose.Schema(
  {
    rowNumber: { type: Number, default: 1 },
    values: { type: [String], default: [] },
  },
  { _id: false }
);

const wellPlanSchema = new mongoose.Schema(
  {
    wellId: {
      type: String,
      required: true,
      index: true,
    },
    reportId: {
      type: String,
      default: "",
      index: true,
    },
    reportNo: {
      type: String,
      default: "",
      trim: true,
    },
    summary: {
      type: [planSummaryItemSchema],
      default: [],
    },
    rows: {
      type: [planRowSchema],
      default: [],
    },
  },
  { timestamps: true }
);

wellPlanSchema.index({ wellId: 1, reportId: 1 });

const WellPlan = mongoose.model("WellPlan", wellPlanSchema);

export default WellPlan;
