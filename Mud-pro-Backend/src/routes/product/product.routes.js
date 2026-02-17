import express from "express";
import { uploadExcel } from "../../middlewares/product/upload.middleware.js";

import {
  addProduct,          // single row add
  bulkAddProducts,     // grid save (JSON array)
  uploadProductExcel,  // excel import
  updateProduct,       // update product
  deleteProduct,       // soft delete
  restoreProduct,      // restore
  getProducts          // get all products
} from "../../controllers/product/product.controller.js";

const router = express.Router();

/* ======================================================
   ADD PRODUCTS
   ====================================================== */

// ➕ Add single product (one row from UI)
router.post("/", addProduct);

// ➕ Bulk add products (Save button – JSON array)
router.post("/bulk", bulkAddProducts);

// 📥 Excel upload (Import button)
router.post("/excel", uploadExcel.single("file"), uploadProductExcel);

/* ======================================================
   FETCH PRODUCTS (UI GRID)
   ====================================================== */
router.get("/", getProducts);

/* ======================================================
   UPDATE PRODUCT
   ====================================================== */
router.put("/:id", updateProduct);

/* ======================================================
   DELETE / RESTORE
   ====================================================== */
router.delete("/:id", deleteProduct);
router.put("/restore/:id", restoreProduct);

export default router;