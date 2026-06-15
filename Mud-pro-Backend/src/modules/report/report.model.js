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

const remarksAttachmentSchema = new mongoose.Schema(
  {
    fileName: {
      type: String,
      default: "",
      trim: true,
    },
    mimeType: {
      type: String,
      default: "",
      trim: true,
    },
    size: {
      type: Number,
      default: 0,
    },
    data: {
      type: String,
      default: "",
    },
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
    recommendedTreatment: {
      type: String,
      default: "",
      trim: true,
    },
    remarks: {
      type: String,
      default: "",
      trim: true,
    },
    recapRemarks: {
      type: String,
      default: "",
      trim: true,
    },
    internalNotes: {
      type: String,
      default: "",
      trim: true,
    },
    remarksAttachment: {
      type: remarksAttachmentSchema,
      default: null,
    },
    pumpRateAndPressure: {
      type: pumpRateAndPressureSchema,
      default: () => ({}),
    },
    operationSelections: {
      type: [String],
      default: [],
    },
    carryOverFromReportId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Report",
      default: null,
    },
    carryOverCompletedAt: {
      type: Date,
      default: null,
    },
    carryOverSourceHoleSnapshot: {
      type: Number,
      default: null,
    },
    carryOverSourceEndVolSnapshot: {
      type: Number,
      default: null,
    },
    carryOverSourceTotalOnLocationSnapshot: {
      type: Number,
      default: null,
    },
    volumeNameHoleSnapshot: {
      type: Number,
      default: null,
    },
    volumeNameHoleDelta: {
      type: Number,
      default: 0,
    },
    volumeNameHoleActivePitsSnapshot: {
      type: Number,
      default: null,
    },
    volumeNameLastActivePitName: {
      type: String,
      trim: true,
      default: "",
    },
    volumeNameLastActivePitVolume: {
      type: Number,
      default: 0,
    },
    volumeNameLastActivePitUpdatedAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

reportSchema.index({ wellId: 1, reportNo: 1 }, { unique: true });

const Report = mongoose.model("Report", reportSchema);

export default Report;
