import mongoose from "mongoose";

const installationDeviceSchema = new mongoose.Schema(
  {
    installationId: {
      type: String,
      required: true,
      trim: true,
      unique: true,
      index: true,
    },
    machineKey: {
      type: String,
      required: true,
      trim: true,
    },
    firstSeenAt: {
      type: Date,
      default: Date.now,
    },
    lastSeenAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

installationDeviceSchema.index({ installationId: 1, machineKey: 1 });

const InstallationDevice = mongoose.model(
  "InstallationDevice",
  installationDeviceSchema
);

export default InstallationDevice;
