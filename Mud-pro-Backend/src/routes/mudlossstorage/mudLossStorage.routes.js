import express from "express";
import {
  createMudLossStorage,
  getMudLossStorageList,
  getMudLossStorageById,
  updateMudLossStorage,
  deleteMudLossStorage,
} from "../../controllers/mudlossstorage/mudLossStorage.controller.js";

const router = express.Router();

router.post("/:wellId", createMudLossStorage);
router.get("/:wellId", getMudLossStorageList);
router.get("/:wellId/:id", getMudLossStorageById);
router.put("/:wellId/:id", updateMudLossStorage);
router.delete("/:wellId/:id", deleteMudLossStorage);

export default router;