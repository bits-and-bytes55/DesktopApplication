import mongoose from "mongoose";

const activityLogSchema = new mongoose.Schema(
  {
    action: String, // UPLOAD, DELETE, RESTORE, UPDATE
    module: { type: String, default: "PRODUCT" },

    performedBy: {
      type: String, // userId / email (future ready)
      default: "SYSTEM"
    },

    referenceId: mongoose.Schema.Types.ObjectId,
    description: String
  },
  { timestamps: true }
);

export default mongoose.model("ActivityLog", activityLogSchema);
