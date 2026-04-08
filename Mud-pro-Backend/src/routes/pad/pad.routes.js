import express from "express";
import {
  createPad,
  getPads,
  getPadById,
  updatePad,
  deletePad,
} from "../../controllers/pad/pad.controller.js";

const router = express.Router();

router.get("/", getPads);
router.post("/", createPad);
router.get("/:id", getPadById);
router.put("/:id", updatePad);
router.delete("/:id", deletePad);

export default router;
