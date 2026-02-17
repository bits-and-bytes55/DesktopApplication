

// routes/others/synthetic.routes.js
import express from "express";
import { 
  createSynthetic, 
  createBulkSynthetic,
  getSynthetic, 
  updateSynthetic, 
  deleteSynthetic 
} from "../../controllers/others/others.controller.js";

const router = express.Router();

router.post("/add-synthetic", createSynthetic);
router.post("/add-bulk-synthetic", createBulkSynthetic);
router.get("/get-synthetic", getSynthetic);
router.put("/:id", updateSynthetic);
router.delete("/:id", deleteSynthetic);

export default router;