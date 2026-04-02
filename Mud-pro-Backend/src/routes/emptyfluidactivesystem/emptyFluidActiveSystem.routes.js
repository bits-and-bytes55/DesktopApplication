import express from "express";
import { createEmptyFluidActiveSystem } from "../../controllers/emptyfluidactivesystem/emptyFluidActiveSystem.controller.js";

const router = express.Router();

router.post("/:wellId", createEmptyFluidActiveSystem);

export default router;