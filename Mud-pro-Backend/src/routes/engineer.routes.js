import { Router } from "express";
const router = Router();
import { createEngineer, getEngineers } from "../controllers/engineer.controller.js";

router.post("/add-engineers", createEngineer);
router.get("/get-engineers", getEngineers);

export default router;
