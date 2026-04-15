import express from "express";
import {
  createAddWater,
  getAddWaterList,
  getAddWaterById,
  updateAddWater,
  deleteAddWater,
} from "../../controllers/addwater/addWater.controller.js";

const router = express.Router();

router.post("/:wellId", createAddWater);
router.get("/:wellId", getAddWaterList);
router.get("/:wellId/:id", getAddWaterById);
router.put("/:wellId/:id", updateAddWater);
router.delete("/:wellId/:id", deleteAddWater);

export default router;