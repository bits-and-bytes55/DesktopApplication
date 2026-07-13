import mongoose from "mongoose";

const accessCodeSchema = new mongoose.Schema(
  {
    codeHash: {
      type: String,
      required: true,
      index: true,
    },
    codeLast4: {
      type: String,
      default: "",
      trim: true,
    },
    deviceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "AuthorizedDevice",
      required: true,
      index: true,
    },
    installationId: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },
    machineKey: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },
    durationDays: {
      type: Number,
      required: true,
      min: 1,
      max: 3650,
    },
    codeExpiresAt: {
      type: Date,
      required: true,
      index: true,
    },
    accessStartsAt: {
      type: Date,
      default: null,
    },
    accessExpiresAt: {
      type: Date,
      default: null,
    },
    usedAt: {
      type: Date,
      default: null,
      index: true,
    },
    usedByInstallationId: {
      type: String,
      default: "",
      trim: true,
    },
    usedByMachineKey: {
      type: String,
      default: "",
      trim: true,
    },
  },
  { timestamps: true }
);

accessCodeSchema.index({ installationId: 1, machineKey: 1, usedAt: 1 });

const AccessCode = mongoose.model("AccessCode", accessCodeSchema);

export default AccessCode;
