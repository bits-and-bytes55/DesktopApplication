import mongoose from "mongoose";

const returnPackageSchema = new mongoose.Schema(
  {
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
