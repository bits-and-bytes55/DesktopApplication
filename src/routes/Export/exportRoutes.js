import express from "express";
import {exportInventoryReport}  from "../../controllers/Export/exportInventoryController.js";

const router = express.Router();

router.get("/inventory-export", exportInventoryReport);

export default router;
