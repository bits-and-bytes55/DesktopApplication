import express from "express";
import { createMudLoss } from "../../controllers/mudloss/mudLoss.controller.js";

const router = express.Router();

router.post("/:wellId", createMudLoss);

export default router;