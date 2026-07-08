import express from "express";
import {
  changeAdminPassword,
  deleteDevice,
  getAdminStatus,
  getDevices,
  getSecurityLogs,
  loginAdmin,
  requireAdminSession,
  resetAdminPassword,
  setupAdminPassword,
  updateDeviceStatus,
  upsertCurrentDevice,
} from "../../controllers/adminControl/adminControl.controller.js";

const router = express.Router();

router.get("/status", getAdminStatus);
router.post("/setup-password", setupAdminPassword);
router.post("/login", loginAdmin);
router.post("/change-password", requireAdminSession, changeAdminPassword);
router.post("/reset-password", resetAdminPassword);
router.get("/devices", requireAdminSession, getDevices);
router.post("/devices/current", requireAdminSession, upsertCurrentDevice);
router.patch("/devices/:id/status", requireAdminSession, updateDeviceStatus);
router.delete("/devices/:id", requireAdminSession, deleteDevice);
router.get("/logs", requireAdminSession, getSecurityLogs);

export default router;
