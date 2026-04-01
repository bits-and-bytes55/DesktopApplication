import express from "express";
import { createPad } from "../../controllers/pad/pad.controller.js";

const router = express.Router();

router.post("/", createPad);

export default router;