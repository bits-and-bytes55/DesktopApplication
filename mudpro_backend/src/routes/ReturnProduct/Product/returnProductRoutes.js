import express from "express";
import {
  createReturnProduct,
  getAllReturnProducts,
  getReturnProductById,
  updateReturnProduct,
  deleteReturnProduct,
} from "../../../controllers/ReturnProduct/Product/returnProductController.js";

const router = express.Router();

// Create
router.post("/", createReturnProduct);

// Get All
router.get("/", getAllReturnProducts);

// Get By ID
router.get("/:id", getReturnProductById);

// Update
router.put("/:id", updateReturnProduct);

// Delete
router.delete("/:id", deleteReturnProduct);

export default router;
