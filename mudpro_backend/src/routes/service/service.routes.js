import express from "express";
import { 
  createService, 
  createBulkServices, // NEW
  getServices, 
  updateService, 
  deleteService 
} from "../../controllers/service/service.controller.js";

const router = express.Router();

// Single service
router.post("/add-service", createService);

// Bulk services (NEW)
router.post("/add-bulk-services", createBulkServices);

// Get all services
router.get("/get-service", getServices);

// Update & Delete
router.put("/:id", updateService);
router.delete("/:id", deleteService);

export default router;