import express from "express";
import { checkDeviceAccess } from "../../controllers/adminControl/deviceAuth.controller.js";

const router = express.Router();

router.post("/check", checkDeviceAccess);

export default router;
