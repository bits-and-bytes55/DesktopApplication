import mongoose from "mongoose";

const packageSchema = new mongoose.Schema({
  name: { type: String, required: true },
  code: { type: String },
  unit: { type: String },
  price: { type: Number, default: 0 },
}, { timestamps: true });

export const Package = mongoose.model("Package", packageSchema);

const serviceSchema = new mongoose.Schema({
  name: { type: String, required: true },
  code: { type: String },
  unit: { type: String },
  price: { type: Number, default: 0 },
}, { timestamps: true });

export const Service = mongoose.model("Service", serviceSchema);

const engineeringSchema = new mongoose.Schema({
  name: { type: String, required: true },
  code: { type: String },
  unit: { type: String },
  price: { type: Number, default: 0 },
}, { timestamps: true });

export const Engineering = mongoose.model("Engineering", engineeringSchema);
