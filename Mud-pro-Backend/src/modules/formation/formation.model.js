import mongoose from "mongoose";

const formationRowSchema = new mongoose.Schema(
  {
    rowNumber: { type: Number, default: 1 },
    description: { type: String, default: "", trim: true },
    tvd: { type: String, default: "", trim: true },
    porePpg: { type: String, default: "", trim: true },
    poreGrad: { type: String, default: "", trim: true },
    porePsi: { type: String, default: "", trim: true },
    fracPpg: { type: String, default: "", trim: true },
    fracGrad: { type: String, default: "", trim: true },
    fracPsi: { type: String, default: "", trim: true },
    lithology: { type: String, default: "", trim: true },
  },
  { _id: false }
);

const formationSchema = new mongoose.Schema(
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
    poreFromTop: {
      type: Boolean,
      default: true,
    },
    mode: {
      type: String,
      enum: ["Density", "Gradient", "Pressure"],
      default: "Gradient",
    },
    rows: {
      type: [formationRowSchema],
      default: [],
    },
  },
  { timestamps: true }
);

formationSchema.index({ wellId: 1, reportId: 1 });

const FormationConfig = mongoose.model("FormationConfig", formationSchema);

export default FormationConfig;
