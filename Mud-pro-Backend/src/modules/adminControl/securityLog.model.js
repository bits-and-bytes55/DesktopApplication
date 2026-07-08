import mongoose from "mongoose";

const securityLogSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },
    message: {
      type: String,
      required: true,
      trim: true,
    },
    installationId: {
      type: String,
      default: "",
      trim: true,
      index: true,
    },
    machineKey: {
      type: String,
      default: "",
      trim: true,
    },
    macAddress: {
      type: String,
      default: "",
      trim: true,
    },
    ipAddress: {
      type: String,
      default: "",
      trim: true,
    },
    hostname: {
      type: String,
      default: "",
      trim: true,
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  { timestamps: true }
);

const SecurityLog = mongoose.model("SecurityLog", securityLogSchema);

export default SecurityLog;
