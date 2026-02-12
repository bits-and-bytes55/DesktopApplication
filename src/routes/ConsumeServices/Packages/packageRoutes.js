import express from "express";
import {
  createPackage,
  getAllPackages,
  getPackageById,
  updatePackage,
  deletePackage,
} from "../../../controllers/ConsumeServices/Package/packageController.js";

const router = express.Router();

// Create
router.post("/", createPackage);

// Get All
router.get("/", getAllPackages);

// Get By ID
router.get("/:id", getPackageById);

// Update
router.put("/:id", updatePackage);

// Delete
router.delete("/:id", deletePackage);

export default router;
