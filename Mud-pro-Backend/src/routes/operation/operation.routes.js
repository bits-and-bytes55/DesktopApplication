import express from "express";
import {
  createOperation,
  getAllOperations,
  getOperationById,
  updateOperation,
  deleteOperation,
} from "../../controllers/operation/operation.controller.js";

const router = express.Router();

router.post("/", createOperation);
router.get("/", getAllOperations);
router.get("/:id", getOperationById);
router.put("/:id", updateOperation);
router.delete("/:id", deleteOperation);

export default router;