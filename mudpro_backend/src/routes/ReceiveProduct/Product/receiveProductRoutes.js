import express from "express";
import {
  createReceiveProduct,
  getAllReceiveProducts,
  getReceiveProductById,
  updateReceiveProduct,
  deleteReceiveProduct,
} from "../../../controllers/ReceiveProduct/Product/receiveProductController.js";

const router = express.Router();

// Create
router.post("/", createReceiveProduct);

// Get All
router.get("/", getAllReceiveProducts);

// Get By ID
router.get("/:id", getReceiveProductById);

// Update
router.put("/:id", updateReceiveProduct);

// Delete
router.delete("/:id", deleteReceiveProduct);

export default router;
