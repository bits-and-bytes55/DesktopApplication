import mongoose from "mongoose";

const solidsSchema = new mongoose.Schema(
  {
    // ── Link to report & sample slot ────────────────────────────────────
    // wellId/reportId: scope this result to the active well/report.
    // sampleIndex: 0=Sample1, 1=Sample2, 2=Sample3
    wellId:      { type: String, default: "", index: true },
    reportId:    { type: String, default: null, index: true },
    sampleIndex: { type: Number, default: 0 },

    // ── Raw inputs (stored so we can re-display / audit) ────────────────
    mudWeight:    { type: Number, default: 0 },
    retortSolids: { type: Number, default: 0 },
    bariteLb:     { type: Number, default: 0 },
    bentoniteLb:  { type: Number, default: 0 },
    brineSG:      { type: Number, default: 1 },

    // ── Calculated outputs ───────────────────────────────────────────────
    totalSolidsLb:      { type: Number, default: 0 },
    hgsLb:              { type: Number, default: 0 },
    hgsPercent:         { type: Number, default: 0 },
    lgsLb:              { type: Number, default: 0 },
    lgsPercent:         { type: Number, default: 0 },
    dissolvedSolids:    { type: Number, default: 0 },
    correctedSolids:    { type: Number, default: 0 },
    bentPercent:        { type: Number, default: 0 },
    drillSolidsLb:      { type: Number, default: 0 },
    drillSolidsPercent: { type: Number, default: 0 },
    dsBentRatio:        { type: Number, default: 0 },
    avgSG:              { type: Number, default: 0 },
  },
  {
    timestamps: true, // adds createdAt + updatedAt automatically
  }
);

// Compound index: one record per (reportId, sampleIndex) combination
solidsSchema.index({ wellId: 1, reportId: 1, sampleIndex: 1 });

export default mongoose.model("SolidsAnalysis", solidsSchema);
