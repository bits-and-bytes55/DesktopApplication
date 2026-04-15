import express from "express";
import {
  createReport,
  getReports,
  getReportById,
  updateReport,
  deleteReport,
} from "../../controllers/report/report.controller.js";

const router = express.Router();

router.get("/", getReports);
router.post("/", createReport);
router.get("/:id", getReportById);
router.put("/:id", updateReport);
router.delete("/:id", deleteReport);

export default router;
