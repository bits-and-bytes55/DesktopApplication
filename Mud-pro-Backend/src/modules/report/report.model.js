import mongoose from "mongoose";

const pumpRateAndPressureSchema = new mongoose.Schema(
  {
    pumpRate: { type: Number, default: 0 },
    pumpPressure: { type: Number, default: 0 },
    boostPumpRate: { type: Number, default: 0 },
    returnRate: { type: Number, default: 0 },
    dhToolsPressureLoss: { type: Number, default: 0 },
    motorPressureLoss: { type: Number, default: 0 },
  },
  { _id: false }
);

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
    pumpRateAndPressure: {
      type: pumpRateAndPressureSchema,
      default: () => ({}),
    },
  },
  { timestamps: true }
);

reportSchema.index({ wellId: 1, reportNo: 1 }, { unique: true });

const Report = mongoose.model("Report", reportSchema);

export default Report;
