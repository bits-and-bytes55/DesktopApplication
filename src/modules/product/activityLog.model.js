import mongoose from "mongoose";

const activityLogSchema = new mongoose.Schema(
  {
    /* =========================
       WHAT ACTION HAPPENED
    ========================== */
    action: {
      type: String,
      required: true,
      enum: [
        "CREATE",        // single product add
        "BULK_CREATE",   // grid save
        "UPLOAD",        // excel import
        "DELETE",        // soft delete
        "RESTORE",       // restore
        "UPDATE"         // future edit
      ]
    },

    /* =========================
       MODULE NAME
    ========================== */
    module: {
      type: String,
      default: "PRODUCT"
    },

    /* =========================
       WHO PERFORMED ACTION
       (future auth ready)
    ========================== */
    performedBy: {
      type: String, // userId / email / role
      default: "SYSTEM"
    },

    /* =========================
       SOURCE OF ACTION
    ========================== */
    source: {
      type: String,
      enum: ["UI", "EXCEL", "API", "SYSTEM"],
      default: "SYSTEM"
    },

    /* =========================
       RELATED RECORD
    ========================== */
    referenceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product"
    },

    /* =========================
       HUMAN READABLE MESSAGE
    ========================== */
    description: {
      type: String,
      required: true
    },

    /* =========================
       EXTRA CONTEXT (OPTIONAL)
       e.g. Code, row count
    ========================== */
    meta: {
      type: Object,
      default: {}
    }
  },
  { timestamps: true }
);

export default mongoose.model("ActivityLog", activityLogSchema);
