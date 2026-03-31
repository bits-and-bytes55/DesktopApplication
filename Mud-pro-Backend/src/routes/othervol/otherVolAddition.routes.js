import express from "express";
import { createOtherVolAddition } from "../../controllers/othervol/otherVolAddition.controller.js";

const router = express.Router();

router.post("/", createOtherVolAddition);

export default router;