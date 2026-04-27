import mongoose from "mongoose";

const timeDistributionRowSchema = new mongoose.Schema(
  {
    description: { type: String, default: "" },
    hours: { type: Number, default: 0 },
  },
  { _id: false }
);

const openHoleRowSchema = new mongoose.Schema(
  {
    description: { type: String, default: "" },
    id: { type: String, default: "" },
    md: { type: String, default: "" },
    washout: { type: String, default: "" },
  },
  { _id: false }
);

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
  bitMft: { type: String, default: "" },
  bitType: { type: String, default: "" },
  bitSize: { type: String, default: "" },
  bitCount: { type: String, default: "" },
  bitDepthIn: { type: String, default: "" },
  bitDepth: { type: String, default: "" },
  additionalFootage: { type: Number, default: 0 },
  nptTime: { type: Number, default: 0 },
  nptCost: { type: Number, default: 0 },
  depthDrilled: { type: Number, default: 0 },
  cementPlugEnabled: { type: Boolean, default: false },
  cementPlugVolume: { type: String, default: "" },
  cementPlugTop: { type: String, default: "" },
  timeDistributionRows: {
    type: [timeDistributionRowSchema],
    default: [],
  },
  openHoleRows: {
    type: [openHoleRowSchema],
    default: [],
  },
}, { timestamps: true });

export default mongoose.model("WellGeneral", wellGeneralSchema);
