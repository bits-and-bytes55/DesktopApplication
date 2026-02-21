import express from "express";
import {
  createConsumeProduct,
  getAllConsumeProducts,
  getConsumeProductById,
  updateConsumeProduct,
  deleteConsumeProduct
} from "../../controllers/ConsumeProduct/consumeProductController.js";

const router = express.Router();

router.post("/", createConsumeProduct);
router.get("/", getAllConsumeProducts);
router.get("/:id", getConsumeProductById);
router.put("/:id", updateConsumeProduct);
router.delete("/:id", deleteConsumeProduct);

export default router;
