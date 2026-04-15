import mongoose from "mongoose";

const receivePackageSchema = new mongoose.Schema(
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

export default mongoose.model("ReceivePackage", receivePackageSchema);
