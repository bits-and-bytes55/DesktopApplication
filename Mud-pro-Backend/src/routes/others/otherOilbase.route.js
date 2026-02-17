// routes/others/oilbased.routes.js
import express from "express";
import { 
  createOilBased, 
  createBulkOilBased,
  getOilBased, 
  updateOilBased, 
  deleteOilBased 
} from "../../controllers/others/others.controller.js";

const router = express.Router();

router.post("/add-oilbased", createOilBased);
router.post("/add-bulk-oilbased", createBulkOilBased);
router.get("/get-oilbased", getOilBased);
router.put("/:id", updateOilBased);
router.delete("/:id", deleteOilBased);

export default router;