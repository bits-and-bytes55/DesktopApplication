import mongoose from "mongoose";

const adminCredentialSchema = new mongoose.Schema(
  {
    passwordHash: {
      type: String,
      required: true,
    },
    passwordSalt: {
      type: String,
      required: true,
    },
    lastChangedAt: {
      type: Date,
      default: Date.now,
    },
    resetCount: {
      type: Number,
      default: 0,
      min: 0,
      max: 2,
    },
    failedAttempts: {
      type: Number,
      default: 0,
      min: 0,
    },
    lockedUntil: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

const AdminCredential = mongoose.model(
  "AdminCredential",
  adminCredentialSchema
);

export default AdminCredential;
