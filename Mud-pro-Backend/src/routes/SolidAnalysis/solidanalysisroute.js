import express from "express";
import {
    createSolidsAnalysis,
    updateSolidsAnalysis,
    getLatestSolidsAnalysis,
    calculateOnly,
} from "../../controllers/SolidAnalysis/solidanalysiscontroller.js";

const router = express.Router();

// POST   /api/solids              → first-time create (returns _id)
router.post("/", createSolidsAnalysis);

// PUT    /api/solids/:id          → update existing record in-place
router.put("/:id", updateSolidsAnalysis);

// GET    /api/solids              → latest record
// GET    /api/solids?limit=5      → last N records
// GET    /api/solids?reportId=X   → filter by report
router.get("/", getLatestSolidsAnalysis);

// POST   /api/solids/calculate    → calculate only, no DB write
router.post("/calculate", calculateOnly);

export default router;