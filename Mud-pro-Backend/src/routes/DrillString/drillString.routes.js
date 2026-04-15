import express from "express";
import {
  createDrillString,
  getDrillStrings,
  deleteDrillString
} from "../../controllers/DrillString/drillString.controller.js";

const router = express.Router();

router.post("/", createDrillString);
router.get("/", getDrillStrings);
router.delete("/:id", deleteDrillString);

export default router;