const express = require("express");
const router = express.Router();
const controller = require("./company.controller");

// GET company details (no image needed)
router.get("/get-company-details", controller.getCompany);

// POST company details with logo image
router.post(
  "/add-company-details",
  controller.uploadLogo,  // Multer middleware
  controller.saveCompany
);

// PUT update company details with logo image
router.put(
  "/update-company-details",
  controller.uploadLogo,  // Multer middleware
  controller.updateCompany
);

module.exports = router;