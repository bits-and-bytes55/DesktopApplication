import mongoose from "mongoose";

const returnPackageSchema = new mongoose.Schema(
  {
    wellId: {
      type: String,
      default: "",
      index: true,
    },

    reportId: {
      type: String,
      default: "",
      index: true,
    },

    operationInstanceKey: {
      type: String,
      default: "",
      index: true,
    },

    packageName: {
      type: String,
      default: "",
    },

    code: {
      type: String,
      default: "",
    },

    unit: {
      type: String,
      default: "",
    },

    amount: {
      type: Number,
      default: 0,
    }

  },
  { timestamps: true }
);

export default mongoose.model("ReturnPackage", returnPackageSchema);
