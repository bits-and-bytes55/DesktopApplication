import express from "express";
import {
  createCatalog,
  createRow,
  createType,
  deleteCatalog,
  deleteRow,
  deleteType,
  getTubularDatabase,
  updateRow,
} from "../../controllers/tubularDatabase/tubularDatabase.controller.js";

const router = express.Router();

router.get("/", getTubularDatabase);
router.post("/types", createType);
router.delete("/types/:id", deleteType);
router.post("/catalogs", createCatalog);
router.delete("/catalogs/:id", deleteCatalog);
router.post("/rows", createRow);
router.put("/rows/:id", updateRow);
router.delete("/rows/:id", deleteRow);

export default router;
