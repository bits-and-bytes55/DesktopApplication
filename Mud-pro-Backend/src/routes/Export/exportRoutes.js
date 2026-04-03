import express from "express";
import {exportInventoryReport}  from "../../controllers/Export/exportInventoryController.js";

const router = express.Router();

router.get("/inventory-export/:wellId", exportInventoryReport);

export default router;
