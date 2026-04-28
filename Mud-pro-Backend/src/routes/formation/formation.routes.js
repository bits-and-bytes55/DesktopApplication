import express from "express";
import {
  deleteFormationConfig,
  getFormationConfig,
  saveFormationConfig,
} from "../../controllers/formation/formation.controller.js";

const router = express.Router();

router.get("/:wellId", getFormationConfig);
router.put("/:wellId", saveFormationConfig);
router.delete("/:wellId", deleteFormationConfig);

export default router;
