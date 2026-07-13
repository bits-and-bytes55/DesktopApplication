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
      enum: ["pending", "allowed", "blocked", "expired"],
      default: "pending",
      index: true,
    },
    accessType: {
      type: String,
      enum: ["none", "permanent", "timed"],
      default: "none",
      index: true,
    },
    accessStartsAt: {
      type: Date,
      default: null,
    },
    accessExpiresAt: {
      type: Date,
      default: null,
      index: true,
    },
    accessDurationDays: {
      type: Number,
      default: 0,
      min: 0,
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
    lastAccessCheckAt: {
      type: Date,
      default: null,
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
