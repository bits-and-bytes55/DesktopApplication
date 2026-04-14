// routes/others/addition.routes.js
import express from "express";
import { 
  createAddition, 
  createBulkAdditions,
  getAdditions, 
  updateAddition, 
  deleteAddition 
} from "../../controllers/others/others.controller.js";

const router = express.Router();

router.post("/add-addition", createAddition);
router.post("/add-bulk-additions", createBulkAdditions);
router.get("/get-additions", getAdditions);
router.put("/:id", updateAddition);
router.delete("/:id", deleteAddition);

export default router;