const mongoose = require("mongoose");

const companySchema = new mongoose.Schema(
  {
    companyName: String,
    address: String,
    phone: String,
    email: String,
    logoUrl: String,
    currencySymbol: String,
    currencyFormat: String,
  },
  { timestamps: true }
);

module.exports = mongoose.model("Company", companySchema);
