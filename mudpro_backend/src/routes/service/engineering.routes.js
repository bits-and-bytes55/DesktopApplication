import express from "express";
import { 
  createEngineering, 
  createBulkEngineering, // NEW
  getEngineering, 
  updateEngineering, 
  deleteEngineering 
} from "../../controllers/service/service.engineering.controller.js";

const router = express.Router();

// Single engineering
router.post("/add-engineering", createEngineering);

// Bulk engineering (NEW)
router.post("/add-bulk-engineering", createBulkEngineering);

// Get all engineering
router.get("/get-engineering", getEngineering);

// Update & Delete
router.put("/:id", updateEngineering);
router.delete("/:id", deleteEngineering);

export default router;