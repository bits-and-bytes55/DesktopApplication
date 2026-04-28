import express from "express";
import {
  deleteSurveyConfig,
  getSurveyConfig,
  saveSurveyConfig,
} from "../../controllers/survey/survey.controller.js";

const router = express.Router();

router.get("/:wellId", getSurveyConfig);
router.put("/:wellId", saveSurveyConfig);
router.delete("/:wellId", deleteSurveyConfig);

export default router;
