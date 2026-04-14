import express from "express";
import {
  createEngineering,
  getAllEngineering,
  getEngineeringById,
  updateEngineering,
  deleteEngineering,
} from "../../../controllers/ConsumeServices/Engineering/engineeringController.js";

const router = express.Router();

// Create
router.post("/", createEngineering);

// Get All
router.get("/", getAllEngineering);

// Get By ID
router.get("/:id", getEngineeringById);

// Update
router.put("/:id", updateEngineering);

// Delete
router.delete("/:id", deleteEngineering);

export default router;
