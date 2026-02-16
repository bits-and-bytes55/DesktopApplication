import mongoose from "mongoose";

const companySchema = new mongoose.Schema(
  {
    companyName: {
      type: String,
      required: true,
    },
    address: {
      type: String,
      required: true,
    },
    phone: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
    },
    logoUrl: {
      type: String,
      default: "",
    },
    currencySymbol: {
      type: String,
      default: "₹",
    },
    currencyFormat: {
      type: String,
      default: "0.00",
    },
  },
  { 
    timestamps: true,
    versionKey: false  // This removes __v field
  }
);

export default mongoose.model("Company", companySchema);