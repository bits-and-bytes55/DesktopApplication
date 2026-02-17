import express from "express";
import {
  createService,
  getAllServices,
  getServiceById,
  updateService,
  deleteService,
} from "../../../controllers/ConsumeServices/Services/serviceController.js";

const router = express.Router();

// Create
router.post("/", createService);

// Get All
router.get("/", getAllServices);

// Get By ID
router.get("/:id", getServiceById);

// Update
router.put("/:id", updateService);

// Delete
router.delete("/:id", deleteService);

export default router;
