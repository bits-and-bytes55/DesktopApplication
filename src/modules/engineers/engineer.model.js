import mongoose from "mongoose";

const engineerSchema = new mongoose.Schema(
  {
    firstName: { type: String, required: true },
    lastName: { type: String, required: true },
    cell: String,
    office: String,
    email: String,
    photoUrl: String,
  },
  { timestamps: true }
);

export default mongoose.model("Engineer", engineerSchema);
