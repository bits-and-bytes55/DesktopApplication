import mongoose from "mongoose";

const nozzleSchema = new mongoose.Schema({
//   wellId: {
//     type: mongoose.Schema.Types.ObjectId,
//     ref: "Well",
//     required: true
//   },

  nozzles: [
    {
      count: { type: Number, required: true },
      size32: { type: Number, required: true },   // example: 16 means 16/32
      diameterInch: { type: Number, default: 0 },
      area: { type: Number, default: 0 }
    }
  ],

  tfa: {
    type: Number,
    default: 0
  }

}, { timestamps: true });

export default mongoose.model("Nozzle", nozzleSchema);