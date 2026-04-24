import express from "express";
import {
  createDrillString,
  getDrillStrings,
  updateDrillString,
  deleteDrillString
} from "../../controllers/DrillString/drillString.controller.js";

const router = express.Router();

router.post("/", createDrillString);
router.get("/", getDrillStrings);
router.put("/:id", updateDrillString);
router.delete("/:id", deleteDrillString);

export default router;
