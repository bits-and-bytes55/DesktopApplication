import mongoose from "mongoose";

const padSchema = new mongoose.Schema(
  {
    locationType: {
      type: String,
      enum: ["Land", "Offshore"],
      default: "Land",
    },

    fieldBlock: {
      type: String,
      default: "",
      trim: true,
    },

    rig: {
      type: String,
      default: "",
      trim: true,
    },

    countyParishOffshoreArea: {
      type: String,
      default: "",
      trim: true,
    },

    stateProvince: {
      type: String,
      default: "",
      trim: true,
    },

    country: {
      type: String,
      default: "",
      trim: true,
    },

    stockPoint: {
      type: String,
      default: "",
      trim: true,
    },

    phone: {
      type: String,
      default: "",
      trim: true,
    },

    operator: {
      type: String,
      default: "",
      trim: true,
    },

    operatorRep: {
      type: String,
      default: "",
      trim: true,
    },

    contractor: {
      type: String,
      default: "",
      trim: true,
    },

    contractorRep: {
      type: String,
      default: "",
      trim: true,
    },

    sl: {
      type: String,
      default: "",
      trim: true,
    },

    airGap: {
      type: Number,
      default: 0,
    },

    waterDepth: {
      type: Number,
      default: 0,
    },

    riserOD: {
      type: Number,
      default: 0,
    },

    riserID: {
      type: Number,
      default: 0,
    },

    chokeLineID: {
      type: Number,
      default: 0,
    },

    killLineID: {
      type: Number,
      default: 0,
    },

    boostLineID: {
      type: Number,
      default: 0,
    },

    memo: {
      type: String,
      default: "",
      trim: true,
    },

    clientLogoUrl: {
      type: String,
      default: "",
      trim: true,
    },

    clientLogoPin: {
      type: String,
      default: "",
      trim: true,
    },
  },
  { timestamps: true }
);

padSchema.index({ fieldBlock: 1 });
padSchema.index({ operator: 1 });
padSchema.index({ country: 1 });

const Pad = mongoose.model("Pad", padSchema);

export default Pad;
