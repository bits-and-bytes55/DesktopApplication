import express from "express";
import {
  createReceivePackage,
  getAllReceivePackages,
  getReceivePackageById,
  updateReceivePackage,
  deleteReceivePackage,
} from "../../../controllers/ReceiveProduct/Package/receivePackageController.js";

const router = express.Router();

// Create
router.post("/", createReceivePackage);

// Get All
router.get("/", getAllReceivePackages);

// Get By ID
router.get("/:id", getReceivePackageById);

// Update
router.put("/:id", updateReceivePackage);

// Delete
router.delete("/:id", deleteReceivePackage);

export default router;
