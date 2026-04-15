import express from "express";
import {
  createReceiveMud,
  getReceiveMudList,
  getReceiveMudById,
  updateReceiveMud,
  deleteReceiveMud,
} from "../../controllers/receivemud/receiveMud.controller.js";

const router = express.Router();

router.post("/:wellId", createReceiveMud);
router.get("/:wellId", getReceiveMudList);
router.get("/:wellId/:id", getReceiveMudById);
router.put("/:wellId/:id", updateReceiveMud);
router.delete("/:wellId/:id", deleteReceiveMud);

export default router;