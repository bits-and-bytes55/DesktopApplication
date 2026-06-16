import mongoose from "mongoose";

// ── Products Inventory ──────────────────────────────────────────
const productItemSchema = new mongoose.Schema({
  product:   { type: String, default: "" },
  code:      { type: String, default: "" },
  sg:        { type: String, default: "" },
  unit:      { type: String, default: "" },
  price:     { type: String, default: "" },
  initial:   { type: String, default: "" },
  group:     { type: String, default: "" },
  volAdd:    { type: Boolean, default: false },
  calculate: { type: Boolean, default: false },
  plot:      { type: Boolean, default: false },
  tax:       { type: Boolean, default: false },
});

// ── Premixed Mud ────────────────────────────────────────────────
const premixedItemSchema = new mongoose.Schema({
  description: { type: String, default: "" },
  mw:          { type: String, default: "" },
  leasingFee:  { type: String, default: "" },
  mudType:     { type: String, default: "" },
  tax:         { type: Boolean, default: false },
});

// ── OBM ─────────────────────────────────────────────────────────
const obmItemSchema = new mongoose.Schema({
  premixDescription: { type: String, default: "" },
  product: { type: String, default: "" },
  code:    { type: String, default: "" },
  sg:      { type: String, default: "" },
  conc:    { type: String, default: "" },
});

// ── Services Categories ──────────────────────────────────────────
// ✅ FIX: packages mein 'initial' field add kiya
const serviceCategoryItemSchema = new mongoose.Schema({
  name:    { type: String, default: "" },
  code:    { type: String, default: "" },
  unit:    { type: String, default: "" },
  price:   { type: String, default: "" },
  initial: { type: String, default: "" }, // ✅ NEW — only packages use this
  tax:     { type: Boolean, default: false },
});

// ── Main Snapshot ────────────────────────────────────────────────
const ugInventorySnapshotSchema = new mongoose.Schema(
  {
    wellId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Well",
      required: true,
      index: true,
    },
    products:    { type: [productItemSchema],         default: [] },
    premixed:    { type: [premixedItemSchema],         default: [] },
    obm:         { type: [obmItemSchema],              default: [] },
    packages:    { type: [serviceCategoryItemSchema],  default: [] },
    engineering: { type: [serviceCategoryItemSchema],  default: [] },
    services:    { type: [serviceCategoryItemSchema],  default: [] },

    // Footer fields
    bulkTankSetupFee: { type: String, default: "" },
    taxRate:          { type: String, default: "" },
    applyPricesOption: {
      type: String,
      enum: ["To All", "From Now On", "From"],
      default: "To All",
    },
    fromDate: { type: String, default: "" },
  },
  { timestamps: true }
);

const UgInventorySnapshot = mongoose.model(
  "UgInventorySnapshot",
  ugInventorySnapshotSchema
);

export default UgInventorySnapshot;
