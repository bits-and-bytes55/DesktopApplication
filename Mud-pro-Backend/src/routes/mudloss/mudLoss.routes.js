import express from "express";
import {
  createMudLoss,
  getMudLossList,
  getMudLossById,
  updateMudLoss,
  deleteMudLoss,
} from "../../controllers/mudloss/mudLoss.controller.js";

const router = express.Router();

router.post("/:wellId", createMudLoss);
router.get("/:wellId", getMudLossList);
router.get("/:wellId/:id", getMudLossById);
router.put("/:wellId/:id", updateMudLoss);
router.delete("/:wellId/:id", deleteMudLoss);

export default router;