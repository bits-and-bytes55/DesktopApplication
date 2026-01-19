import express from "express";
import { uploadExcel } from "../../middlewares/product/upload.middleware.js";
import {
  uploadProductExcel,
  deleteProduct,
  restoreProduct,
  getProducts
} from "../../controllers/product/product.controller.js";

const router = express.Router();

// ✅ THIS LINE MUST EXIST
router.post("/bulk", uploadExcel.single("file"), uploadProductExcel);
router.get("/", getProducts);
router.delete("/:id", deleteProduct);
router.put("/restore/:id", restoreProduct);

export default router;
