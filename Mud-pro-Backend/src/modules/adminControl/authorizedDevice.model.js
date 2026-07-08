import mongoose from "mongoose";

const authorizedDeviceSchema = new mongoose.Schema(
  {
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
    appVersion: {
      type: String,
      default: "",
      trim: true,
    },
    status: {
      type: String,
      enum: ["pending", "allowed", "blocked"],
      default: "pending",
      index: true,
    },
    approvedAt: {
      type: Date,
      default: null,
    },
    blockedAt: {
      type: Date,
      default: null,
    },
    lastSeenAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

authorizedDeviceSchema.index(
  { installationId: 1, machineKey: 1 },
  { unique: true }
);

const AuthorizedDevice = mongoose.model(
  "AuthorizedDevice",
  authorizedDeviceSchema
);

export default AuthorizedDevice;
