import express from "express";
import { createReceiveMud } from "../../controllers/receivemud/receiveMud.controller.js";

const router = express.Router();

router.post("/:wellId", createReceiveMud);

export default router;