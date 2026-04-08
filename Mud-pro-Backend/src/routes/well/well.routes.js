import express from "express";
import {
  createWell,
  getAllWells,
  getWellsByPad,
  getWellById,
  updateWell,
  deleteWell,
} from "../../controllers/well/well.controller.js";

const router = express.Router();

router.get("/", getAllWells);
router.post("/", createWell);
router.get("/pad/:padId", getWellsByPad);
router.get("/:id", getWellById);
router.put("/:id", updateWell);
router.delete("/:id", deleteWell);

export default router;
