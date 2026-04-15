import express from "express";
import { createNozzle, getNozzles, updateNozzle } from "../../controllers/nozzle/nozzle.controller.js";

const router = express.Router();

router.post("/well", createNozzle);       // POST /api/nozzle/well
router.get("/", getNozzles);              // GET  /api/nozzle
router.put("/:id", updateNozzle);         // PUT  /api/nozzle/:id

export default router;