import express from "express";
import {
  createWellGeneral,
  getWellGenerals,
  getWellGeneralById,
  updateWellGeneral,
  deleteWellGeneral,
} from "../../controllers/wellGeneral/wellGeneralController.js";

const router = express.Router();

router.post("/", createWellGeneral);
router.get("/", getWellGenerals);
router.get("/:id", getWellGeneralById);
router.put("/:id", updateWellGeneral);
router.delete("/:id", deleteWellGeneral);

export default router;