import express from "express";
import {
  getUgInventory,
  saveUgInventory,
  getUgInventoryProducts,
  getUgInventoryPackages,
  getUgInventoryEngineering,
  getUgInventoryServices,
} from "../../controllers/ugInventory/ugInventoryProductController.js";

const router = express.Router();

// GET  /api/ug-inventory/:wellId  → fetch full snapshot
router.get("/:wellId", getUgInventory);

// Specific GET routes
router.get("/products/:wellId", getUgInventoryProducts);
router.get("/packages/:wellId", getUgInventoryPackages);
router.get("/engineering/:wellId", getUgInventoryEngineering);
router.get("/services/:wellId", getUgInventoryServices);

// POST /api/ug-inventory/:wellId  → save/upsert snapshot
router.post("/:wellId", saveUgInventory);

export default router;