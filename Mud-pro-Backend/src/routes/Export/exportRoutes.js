import express from "express";
import {
  exportCostOfPadReport,
  exportInventoryReport,
} from "../../controllers/Export/exportInventoryController.js";

const router = express.Router();

router.get("/inventory-export/:wellId", exportInventoryReport);
router.get("/cost-of-pad-export/:padId", exportCostOfPadReport);

export default router;
