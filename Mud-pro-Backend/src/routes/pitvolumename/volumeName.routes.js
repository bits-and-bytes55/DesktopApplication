import express from "express";
import {
  createWellGeneral,
  createCasing,
  createConsumeProduct,
  getVolumeNameCalculation,
} from "../../controllers/pitvolumename/volumeName.controller.js";

const router = express.Router();

router.post("/:wellId/well-general", createWellGeneral);
router.post("/:wellId/casing", createCasing);
router.post("/:wellId/consume-product", createConsumeProduct);
router.get("/:wellId", getVolumeNameCalculation);

export default router;