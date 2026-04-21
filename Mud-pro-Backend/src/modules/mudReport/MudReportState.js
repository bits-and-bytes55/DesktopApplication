import mongoose from "mongoose";

const mudReportStateSchema = new mongoose.Schema(
  {
    wellId: { type: String, required: true, index: true },
    reportId: { type: String, default: "", index: true },
    fluidName: { type: String, default: "" },
    fluidType: { type: String, default: "" },
    isCompletionFluid: { type: Boolean, default: false },
    isWeightedMud: { type: Boolean, default: false },
    samples: { type: [String], default: [] },
    propertyTable: { type: mongoose.Schema.Types.Mixed, default: {} },
    propertyUnits: { type: mongoose.Schema.Types.Mixed, default: {} },
    rheologyModel: { type: String, default: "" },
    rheologyCalculation: { type: String, default: "" },
    rheologyTable: { type: mongoose.Schema.Types.Mixed, default: {} },
    sampleForCalculation: { type: String, default: "" },
    oilSg: { type: String, default: "" },
    hgsSg: { type: String, default: "" },
    lgsSg: { type: String, default: "" },
    shaleCec: { type: String, default: "" },
    bentCec: { type: String, default: "" },
  },
  { timestamps: true }
);

mudReportStateSchema.index({ wellId: 1, reportId: 1 }, { unique: true });

export default mongoose.model("MudReportState", mudReportStateSchema);
