import mongoose from "mongoose";

const wellGeneralSchema = new mongoose.Schema({
  wellId: {
    type: String,
    required: true,
    index: true
  },
  reportId: {
    type: String,
    default: "",
    index: true
  },
  reportNo: { type: String, default: "" },
  userReportNo: { type: String, default: "" },
  date: { type: String, default: "" },
  time: { type: String, default: "" },
  engineer: { type: String, default: "" },
  engineer2: { type: String, default: "" },
  operatorRep: { type: String, default: "" },
  contractorRep: { type: String, default: "" },
  activity: { type: String, default: "" },
  md: { type: Number, default: 0 },
  tvd: { type: Number, default: 0 },
  inc: { type: Number, default: 0 },
  azi: { type: Number, default: 0 },
  wob: { type: Number, default: 0 },
  rotWt: { type: Number, default: 0 },
  soWt: { type: Number, default: 0 },
  puWt: { type: Number, default: 0 },
  rpm: { type: Number, default: 0 },
  rop: { type: Number, default: 0 },
  offBottomTq: { type: Number, default: 0 },
  onBottomTq: { type: Number, default: 0 },
  suctionT: { type: Number, default: 0 },
  bottomT: { type: Number, default: 0 },
  interval: { type: String, default: "" },
  fit: { type: String, default: "" },
  formation: { type: String, default: "" },
  additionalFootage: { type: Number, default: 0 },
  nptTime: { type: Number, default: 0 },
  nptCost: { type: Number, default: 0 },
  depthDrilled: { type: Number, default: 0 },
}, { timestamps: true });

export default mongoose.model("WellGeneral", wellGeneralSchema);
