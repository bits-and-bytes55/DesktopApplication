import express from "express";
import {
  createReturnLostMud,
  getReturnLostMudList,
  getReturnLostMudById,
  updateReturnLostMud,
  deleteReturnLostMud,
} from "../../controllers/returnlostmud/returnLostMud.controller.js";

const router = express.Router();

router.post("/:wellId", createReturnLostMud);
router.get("/:wellId", getReturnLostMudList);
router.get("/:wellId/:id", getReturnLostMudById);
router.put("/:wellId/:id", updateReturnLostMud);
router.delete("/:wellId/:id", deleteReturnLostMud);

export default router;