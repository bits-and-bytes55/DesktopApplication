import express from "express";
import { createReturnLostMud } from "../../controllers/returnlostmud/returnLostMud.controller.js";

const router = express.Router();

router.post("/:wellId", createReturnLostMud);

export default router;