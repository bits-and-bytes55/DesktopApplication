import mongoose from "mongoose";

const tubularDatabaseSchema = new mongoose.Schema(
  {
    kind: {
      type: String,
      enum: ["type", "catalog", "material", "row"],
      required: true,
      index: true,
    },
    name: {
      type: String,
      trim: true,
      default: "",
    },
    type: {
      type: String,
      trim: true,
      default: "",
      index: true,
    },
    catalog: {
      type: String,
      trim: true,
      default: "",
      index: true,
    },
    material: {
      type: String,
      trim: true,
      default: "",
    },
    sortOrder: {
      type: Number,
      default: 0,
      index: true,
    },
    od: { type: String, default: "" },
    id: { type: String, default: "" },
    nominalWt: { type: String, default: "" },
    wallThickness: { type: String, default: "" },
    driftId: { type: String, default: "" },
    grade: { type: String, default: "" },
    yieldPsi: { type: String, default: "" },
    fatigueEndurance: { type: String, default: "" },
    ultimateTensile: { type: String, default: "" },
    collapseStr: { type: String, default: "" },
    burstStr: { type: String, default: "" },
    tensileStr: { type: String, default: "" },
    compressiveStr: { type: String, default: "" },
    torsionalStr: { type: String, default: "" },
    connectionType: { type: String, default: "" },
    connectionOd: { type: String, default: "" },
    connectionId: { type: String, default: "" },
    connectionGrade: { type: String, default: "" },
    connectionYield: { type: String, default: "" },
    connectionUts: { type: String, default: "" },
    connectionBurst: { type: String, default: "" },
    connectionTensile: { type: String, default: "" },
    connectionCompressive: { type: String, default: "" },
    connectionTorsional: { type: String, default: "" },
    makeupTorque: { type: String, default: "" },
    assemblyAdjustWt: { type: String, default: "" },
  },
  { timestamps: true }
);

tubularDatabaseSchema.index({ kind: 1, name: 1 });
tubularDatabaseSchema.index({ kind: 1, type: 1, catalog: 1, sortOrder: 1 });

export default mongoose.model("TubularDatabase", tubularDatabaseSchema);
