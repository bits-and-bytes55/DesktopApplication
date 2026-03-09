import express from "express";
import { createSolidsAnalysis } from "../../controllers/SolidAnalysis/solidanalysiscontroller.js";

const router = express.Router();

router.post("/", createSolidsAnalysis);

export default router;