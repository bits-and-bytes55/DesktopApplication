import { Router } from "express";
const router = Router();
import { getCompany, uploadLogo, saveCompany, updateCompany } from "../controllers/company.controller.js";

// GET company details (no image needed)
router.get("/get-company-details", getCompany);

// POST company details with logo image
router.post(
  "/add-company-details",
  uploadLogo,  // Multer middleware
  saveCompany
);

// PUT update company details with logo image
router.put(
  "/update-company-details",
  uploadLogo,  // Multer middleware
  updateCompany
);

export default router;