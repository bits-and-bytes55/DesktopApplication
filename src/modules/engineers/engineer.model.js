const mongoose = require("mongoose");

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

module.exports = mongoose.model("Engineer", engineerSchema);
