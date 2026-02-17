// routes/others/loss.routes.js
import express from "express";
import { 
  createLoss, 
  createBulkLosses,
  getLosses, 
  updateLoss, 
  deleteLoss 
} from "../../controllers/others/others.controller.js";

const router = express.Router();

router.post("/add-loss", createLoss);
router.post("/add-bulk-losses", createBulkLosses);
router.get("/get-losses", getLosses);
router.put("/:id", updateLoss);
router.delete("/:id", deleteLoss);

export default router;