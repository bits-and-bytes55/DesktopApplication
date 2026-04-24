import express from "express";
import {
  createReport,
  getReports,
  getReportManagerRows,
  getReportById,
  updateReport,
  deleteReport,
} from "../../controllers/report/report.controller.js";

const router = express.Router();

router.get("/", getReports);
router.get("/manager", getReportManagerRows);
router.post("/", createReport);
router.get("/:id", getReportById);
router.put("/:id", updateReport);
router.delete("/:id", deleteReport);

export default router;
