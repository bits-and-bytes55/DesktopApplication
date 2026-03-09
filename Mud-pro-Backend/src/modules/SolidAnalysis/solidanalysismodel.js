import mongoose from "mongoose";

const solidsSchema = new mongoose.Schema({

  mudWeight: Number,
  retortSolids: Number,
  bariteLb: Number,
  bentoniteLb: Number,
  brineSG: Number,

  totalSolidsLb: Number,

  hgsLb: Number,
  hgsPercent: Number,

  lgsLb: Number,
  lgsPercent: Number,

  dissolvedSolids: Number,
  correctedSolids: Number,

  bentPercent: Number,

  drillSolidsLb: Number,
  drillSolidsPercent: Number,

  dsBentRatio: Number,

  avgSG: Number

}, { timestamps: true });

export default mongoose.model("SolidsAnalysis", solidsSchema);