import express from "express";
import {
  createWellGeneral,
  createCasing,
  createPit,
  createConsumeProduct,
  getVolumeNameCalculation,
} from "../../controllers/pitvolumename/volumeName.controller.js";

const router = express.Router();

router.post("/well-general", createWellGeneral);
router.post("/casing", createCasing);
router.post("/pit", createPit);
router.post("/consume-product", createConsumeProduct);
router.get("/:wellId", getVolumeNameCalculation);

export default router;