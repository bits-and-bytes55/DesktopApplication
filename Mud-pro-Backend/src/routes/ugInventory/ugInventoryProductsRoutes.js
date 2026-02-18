import express from "express";
import {
  getUgInventory,
  saveUgInventory,
} from "../../controllers/ugInventory/ugInventoryProductController.js";

const router = express.Router();

// GET  /api/ug-inventory/:wellId  → fetch snapshot
router.get("/:wellId", getUgInventory);

// POST /api/ug-inventory/:wellId  → save/upsert snapshot
router.post("/:wellId", saveUgInventory);

export default router;