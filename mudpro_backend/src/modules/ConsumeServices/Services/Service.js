import mongoose from "mongoose";

const ConsumeServiceSchema = new mongoose.Schema(
  {
    serviceName: {
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

    price: {
      type: Number,
      default: 0,
    },

    usage: {
      type: Number,
      default: 0,
    },

    cost: {
      type: Number,
      default: 0,
    }
  },
  { timestamps: true }
);

export default mongoose.model("ConsumeService", ConsumeServiceSchema);
