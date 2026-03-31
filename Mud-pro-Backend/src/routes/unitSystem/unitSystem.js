import express from "express";
import {
  getAllUnitSystems,
  getUnitSystemById,
  createUnitSystem,
  updateUnitSystem,
  updateSingleParameterUnit,
  deleteUnitSystem,
  seedDefaultSystems,
} from "../../controllers/unitSystemController/unitSystemController.js";

const router = express.Router();

// ── CRUD ──────────────────────────────────────────────────────────────────────

// GET    /api/unit-systems            → all systems (left panel list)
router.get("/", getAllUnitSystems);

// GET    /api/unit-systems/:id        → one system with all parameters
router.get("/:id", getUnitSystemById);

// POST   /api/unit-systems            → create new (Insert Before / After)
router.post("/", createUnitSystem);

// PUT    /api/unit-systems/:id        → full update (Save Changes button)
router.put("/:id", updateUnitSystem);

// PATCH  /api/unit-systems/:id/parameter/:number → single unit auto-save on dropdown change
router.patch("/:id/parameter/:number", updateSingleParameterUnit);

// DELETE /api/unit-systems/:id        → delete (Delete Selected button)
router.delete("/:id", deleteUnitSystem);

// ── One-time seed ─────────────────────────────────────────────────────────────
// POST   /api/unit-systems/seed       → seed Pegasus Default 1, SI, US
router.post("/seed", seedDefaultSystems);

export default router;