import express from "express";
import { 
  createPackage, 
  createBulkPackages, // NEW
  getPackages, 
  updatePackage, 
  deletePackage 
} from "../../controllers/service/servicepackage.controller.js";

const router = express.Router();

// Single package
router.post("/add-package", createPackage);

// Bulk packages (NEW)
router.post("/add-bulk-packages", createBulkPackages);

// Get all packages
router.get("/get-package", getPackages);

// Update & Delete
router.put("/:id", updatePackage);
router.delete("/:id", deletePackage);

export default router;