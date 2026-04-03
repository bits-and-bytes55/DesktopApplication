import express from "express";
import {
  movePitStatus,
  getPitStatusList,
  getPitStatusById,
  updateSinglePitStatus,
} from "../../controllers/movepit/movePitStatus.controller.js";

const router = express.Router();

router.post("/:wellId", movePitStatus);
router.get("/:wellId", getPitStatusList);
router.get("/:wellId/:id", getPitStatusById);
router.put("/:wellId/:id", updateSinglePitStatus);

export default router;