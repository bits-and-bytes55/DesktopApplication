import express from "express";
import { movePitStatus } from "../../controllers/movepit/movePitStatus.controller.js";

const router = express.Router();

router.post("/:wellId", movePitStatus);

export default router;