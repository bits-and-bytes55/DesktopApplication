// routes/others/waterbased.routes.js
import express from "express";
import { 
  createWaterBased, 
  createBulkWaterBased,
  getWaterBased, 
  updateWaterBased, 
  deleteWaterBased 
} from "../../controllers/others/others.controller.js";

const router = express.Router();

router.post("/add-waterbased", createWaterBased);
router.post("/add-bulk-waterbased", createBulkWaterBased);
router.get("/get-waterbased", getWaterBased);
router.put("/:id", updateWaterBased);
router.delete("/:id", deleteWaterBased);

export default router;