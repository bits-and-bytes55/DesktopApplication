import express from "express";
import {
  createWellGeneral,
  getWellGenerals,
  getWellGeneralById,
  updateWellGeneral,
  deleteWellGeneral,
} from "../../controllers/wellGeneral/wellGeneralController.js";

const router = express.Router();

router.post("/:wellId", createWellGeneral);
router.get("/:wellId", getWellGenerals);
router.get("/:wellId/:id", getWellGeneralById);
router.put("/:wellId/:id", updateWellGeneral);
router.delete("/:wellId/:id", deleteWellGeneral);

export default router;