import express from "express";
import { generateInventorySnapshot ,getInventorySnapshot} from "../../controllers/FullInventory/inventorySnapshotController.js";

const router = express.Router();

router.post("/generate", generateInventorySnapshot);
router.get("/", getInventorySnapshot);

export default router;
