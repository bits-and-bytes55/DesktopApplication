import express from "express";
import {
  changeAdminPassword,
  deleteDevice,
  generateAccessCode,
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

const publicRouter = express.Router();
const protectedRouter = express.Router();

publicRouter.get("/status", getAdminStatus);
publicRouter.post("/setup-password", setupAdminPassword);
publicRouter.post("/login", loginAdmin);
publicRouter.post("/reset-password", resetAdminPassword);

protectedRouter.post("/change-password", requireAdminSession, changeAdminPassword);
protectedRouter.get("/devices", requireAdminSession, getDevices);
protectedRouter.post("/devices/current", requireAdminSession, upsertCurrentDevice);
protectedRouter.patch("/devices/:id/status", requireAdminSession, updateDeviceStatus);
protectedRouter.post(
  "/devices/:id/access-code",
  requireAdminSession,
  generateAccessCode
);
protectedRouter.delete("/devices/:id", requireAdminSession, deleteDevice);
protectedRouter.get("/logs", requireAdminSession, getSecurityLogs);

export { publicRouter as publicAdminControlRoutes };
export default protectedRouter;
