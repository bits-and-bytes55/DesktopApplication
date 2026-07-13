import express from "express";
import {
  checkDeviceAccess,
  verifyAccessCode,
} from "../../controllers/adminControl/deviceAuth.controller.js";

const router = express.Router();

router.post("/check", checkDeviceAccess);
router.post("/verify-code", verifyAccessCode);

export default router;
