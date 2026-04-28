import mongoose from "mongoose";

const surveyRowSchema = new mongoose.Schema(
  {
    rowNumber: { type: Number, default: 1 },
    md: { type: String, default: "", trim: true },
    inc: { type: String, default: "", trim: true },
    azi: { type: String, default: "", trim: true },
    tvd: { type: String, default: "", trim: true },
    vsec: { type: String, default: "", trim: true },
    northSouth: { type: String, default: "", trim: true },
    eastWest: { type: String, default: "", trim: true },
    dogleg: { type: String, default: "", trim: true },
  },
  { _id: false }
);

const surveyAnnotationSchema = new mongoose.Schema(
  {
    rowNumber: { type: Number, default: 1 },
    md: { type: String, default: "", trim: true },
    annotation: { type: String, default: "", trim: true },
    symbol: { type: String, default: "", trim: true },
  },
  { _id: false }
);

const surveySchema = new mongoose.Schema(
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
    plannedSurvey: {
      type: Boolean,
      default: true,
    },
    annotationEnabled: {
      type: Boolean,
      default: true,
    },
    projectAziEnabled: {
      type: Boolean,
      default: false,
    },
    projectAzi: {
      type: String,
      default: "",
      trim: true,
    },
    rows: {
      type: [surveyRowSchema],
      default: [],
    },
    annotations: {
      type: [surveyAnnotationSchema],
      default: [],
    },
  },
  { timestamps: true }
);

surveySchema.index({ wellId: 1, reportId: 1 });

const SurveyConfig = mongoose.model("SurveyConfig", surveySchema);

export default SurveyConfig;
