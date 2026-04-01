import express from "express";
import { createAddWater } from "../../controllers/addwater/addWater.controller.js";

const router = express.Router();

router.post("/:wellId", createAddWater);

export default router;