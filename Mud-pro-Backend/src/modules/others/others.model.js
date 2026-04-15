// models/others.model.js

import mongoose from "mongoose";

const activitySchema = new mongoose.Schema({
  description: { type: String, required: true },
  hours: { type: Number, default: 0 }   // 👈 new field
}, { timestamps: true });

export const Activity = mongoose.model("Activity", activitySchema);

// Addition Schema
const additionSchema = new mongoose.Schema({
  name: { type: String, required: true },
}, { timestamps: true });

export const Addition = mongoose.model("Addition", additionSchema);

// Loss Schema
const lossSchema = new mongoose.Schema({
  name: { type: String, required: true },
}, { timestamps: true });

export const Loss = mongoose.model("Loss", lossSchema);

// Water-Based Schema
const waterBasedSchema = new mongoose.Schema({
  name: { type: String, required: true },
}, { timestamps: true });

export const WaterBased = mongoose.model("WaterBased", waterBasedSchema);

// Oil-Based Schema
const oilBasedSchema = new mongoose.Schema({
  name: { type: String, required: true },
}, { timestamps: true });

export const OilBased = mongoose.model("OilBased", oilBasedSchema);

// Synthetic Schema
const syntheticSchema = new mongoose.Schema({
  name: { type: String, required: true },
}, { timestamps: true });

export const Synthetic = mongoose.model("Synthetic", syntheticSchema);