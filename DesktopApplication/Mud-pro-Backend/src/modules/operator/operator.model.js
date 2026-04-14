import mongoose from "mongoose";

const operatorSchema = new mongoose.Schema(
  {
    company: { type: String, required: true },
    contact: { type: String },
    address: { type: String },
    phone: { type: String },
    email: { type: String },
    logoUrl: { type: String },
  },
  { timestamps: true }
);

export default mongoose.model("Operator", operatorSchema);
