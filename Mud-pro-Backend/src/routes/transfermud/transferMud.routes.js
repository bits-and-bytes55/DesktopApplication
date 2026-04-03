import express from "express";
import {
  createTransferMud,
  createManyTransferMud,
  getTransferMudByWell,
  getTransferMudById,
  updateTransferMud,
  deleteTransferMud,
} from "../../controllers/transfermud/transferMud.controller.js";

const router = express.Router();

router.post("/:wellId", createTransferMud);
router.post("/:wellId/bulk", createManyTransferMud);
router.get("/:wellId", getTransferMudByWell);
router.get("/:wellId/:id", getTransferMudById);
router.put("/:wellId/:id", updateTransferMud);
router.delete("/:wellId/:id", deleteTransferMud);

export default router;