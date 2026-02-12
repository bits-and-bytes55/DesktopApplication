import express from "express";
import {
  createReturnPackage,
  getAllReturnPackages,
  getReturnPackageById,
  updateReturnPackage,
  deleteReturnPackage,
} from "../../../controllers/ReturnProduct/Package/returnPackageController.js";

const router = express.Router();

// Create
router.post("/", createReturnPackage);

// Get All
router.get("/", getAllReturnPackages);

// Get By ID
router.get("/:id", getReturnPackageById);

// Update
router.put("/:id", updateReturnPackage);

// Delete
router.delete("/:id", deleteReturnPackage);

export default router;
