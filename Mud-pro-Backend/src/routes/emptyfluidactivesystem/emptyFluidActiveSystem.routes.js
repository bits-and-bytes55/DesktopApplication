import express from "express";
import {
  createEmptyFluidActiveSystem,
  getEmptyFluidList,
  getEmptyFluidById,
  updateEmptyFluid,
  deleteEmptyFluid,
} from "../../controllers/emptyfluidactivesystem/emptyFluidActiveSystem.controller.js";

const router = express.Router();

router.post("/:wellId", createEmptyFluidActiveSystem);
router.get("/:wellId", getEmptyFluidList);
router.get("/:wellId/:id", getEmptyFluidById);
router.put("/:wellId/:id", updateEmptyFluid);
router.delete("/:wellId/:id", deleteEmptyFluid);

export default router;