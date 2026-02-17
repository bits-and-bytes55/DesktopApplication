import mongoose from "mongoose";

const returnProductSchema = new mongoose.Schema(
  {
    productName: {
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

export default mongoose.model("ReturnProduct", returnProductSchema);
