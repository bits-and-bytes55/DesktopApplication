import mongoose from "mongoose";

const wellSchema = new mongoose.Schema(
  {
    padId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Pad",
      required: true,
      index: true,
    },

    wellNameNo: {
      type: String,
      required: true,
      trim: true,
    },

    apiWellNo: {
      type: String,
      default: "",
      trim: true,
    },

    spudDate: {
      type: String,
      default: "",
      trim: true,
    },

    sectionTownshipRange: {
      type: String,
      default: "",
      trim: true,
    },

    longitude: {
      type: String,
      default: "",
      trim: true,
    },

    latitude: {
      type: String,
      default: "",
      trim: true,
    },

    kop: {
      type: Number,
      default: 0,
    },

    lp: {
      type: Number,
      default: 0,
    },

    bulkTankSetupFee: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

wellSchema.index({ padId: 1 });
wellSchema.index({ wellNameNo: 1 });
wellSchema.index({ apiWellNo: 1 });

const Well = mongoose.model("Well", wellSchema);

export default Well;