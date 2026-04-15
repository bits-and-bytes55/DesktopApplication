import express from "express";
import {
  createOtherVolAddition,
  getOtherVolAdditionList,
  getOtherVolAdditionById,
  updateOtherVolAddition,
  deleteOtherVolAddition,
} from "../../controllers/othervol/otherVolAddition.controller.js";

const router = express.Router();

router.post("/", createOtherVolAddition);
router.get("/:wellId", getOtherVolAdditionList);
router.get("/:wellId/:id", getOtherVolAdditionById);
router.put("/:wellId/:id", updateOtherVolAddition);
router.delete("/:wellId/:id", deleteOtherVolAddition);

export default router;