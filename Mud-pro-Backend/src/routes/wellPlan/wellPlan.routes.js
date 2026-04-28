import express from "express";
import {
  deleteWellPlan,
  getWellPlan,
  saveWellPlan,
} from "../../controllers/wellPlan/wellPlan.controller.js";

const router = express.Router();

router.get("/:wellId", getWellPlan);
router.put("/:wellId", saveWellPlan);
router.delete("/:wellId", deleteWellPlan);

export default router;
