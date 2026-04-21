import express from "express";
import {
  getMudReportState,
  saveMudReportState,
} from "../../controllers/mudReport/mudReportStateController.js";

const router = express.Router();

router.get("/:wellId", getMudReportState);
router.post("/:wellId", saveMudReportState);
router.put("/:wellId", saveMudReportState);

export default router;
