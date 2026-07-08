import crypto from "node:crypto";
import AdminCredential from "../../modules/adminControl/adminCredential.model.js";
import AuthorizedDevice from "../../modules/adminControl/authorizedDevice.model.js";
import SecurityLog from "../../modules/adminControl/securityLog.model.js";

const PASSWORD_MAX_AGE_DAYS = 30;
const RESET_LIMIT = 2;
const SESSION_TTL_MS = 30 * 60 * 1000;
const adminSessions = new Map();

const toText = (value) => String(value ?? "").trim();

const devicePayloadFromRequest = (req) => ({
  installationId: toText(req.installationId),
  machineKey: toText(req.machineKey),
  macAddress: toText(req.body?.macAddress),
  ipAddress: toText(req.body?.ipAddress) || toText(req.ip),
  hostname: toText(req.body?.hostname),
  appVersion: toText(req.body?.appVersion),
});

const createPasswordHash = (password) => {
  const salt = crypto.randomBytes(16).toString("hex");
  const hash = crypto.scryptSync(password, salt, 64).toString("hex");
  return { hash, salt };
};

const verifyPassword = (password, credential) => {
  const inputHash = crypto
    .scryptSync(password, credential.passwordSalt, 64)
    .toString("hex");
  return crypto.timingSafeEqual(
    Buffer.from(inputHash, "hex"),
    Buffer.from(credential.passwordHash, "hex")
  );
};

const passwordStatus = (credential) => {
  if (!credential) {
    return {
      isSetup: false,
      expired: false,
      daysRemaining: PASSWORD_MAX_AGE_DAYS,
      lastChangedAt: null,
      resetCount: 0,
    };
  }

  const lastChangedAt = credential.lastChangedAt || credential.createdAt;
  const ageMs = Date.now() - new Date(lastChangedAt).getTime();
  const ageDays = Math.floor(ageMs / (24 * 60 * 60 * 1000));
  return {
    isSetup: true,
    expired: ageDays >= PASSWORD_MAX_AGE_DAYS,
    daysRemaining: Math.max(0, PASSWORD_MAX_AGE_DAYS - ageDays),
    lastChangedAt,
    resetCount: credential.resetCount || 0,
  };
};

const logSecurityEvent = async (type, message, req, metadata = {}) => {
  try {
    const device = devicePayloadFromRequest(req);
    await SecurityLog.create({
      type,
      message,
      ...device,
      metadata,
    });
  } catch (error) {
    console.error("Security log failed:", error.message);
  }
};

const createAdminSession = () => {
  const token = crypto.randomBytes(32).toString("hex");
  adminSessions.set(token, Date.now() + SESSION_TTL_MS);
  return token;
};

export const requireAdminSession = (req, res, next) => {
  const token = toText(req.headers?.["x-admin-session-token"]);
  const expiresAt = adminSessions.get(token);
  if (!token || !expiresAt || expiresAt <= Date.now()) {
    if (token) adminSessions.delete(token);
    return res.status(401).json({
      success: false,
      message: "Admin login required",
    });
  }

  adminSessions.set(token, Date.now() + SESSION_TTL_MS);
  return next();
};

export const getAdminStatus = async (_req, res) => {
  try {
    const credential = await AdminCredential.findOne().sort({ createdAt: 1 });
    return res.status(200).json({
      success: true,
      data: passwordStatus(credential),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to load admin status",
      error: error.message,
    });
  }
};

export const setupAdminPassword = async (req, res) => {
  try {
    const existing = await AdminCredential.findOne();
    if (existing) {
      return res.status(409).json({
        success: false,
        message: "Admin password is already configured",
      });
    }

    const password = toText(req.body?.password);
    const confirmPassword = toText(req.body?.confirmPassword);
    if (!password || password.length < 8 || password !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "Password must be at least 8 characters and match confirmation",
      });
    }

    const { hash, salt } = createPasswordHash(password);
    const credential = await AdminCredential.create({
      passwordHash: hash,
      passwordSalt: salt,
      lastChangedAt: new Date(),
    });

    await logSecurityEvent("admin_password_setup", "Admin password configured", req);

    return res.status(201).json({
      success: true,
      message: "Admin password configured",
      data: passwordStatus(credential),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to configure admin password",
      error: error.message,
    });
  }
};

export const loginAdmin = async (req, res) => {
  try {
    const credential = await AdminCredential.findOne().sort({ createdAt: 1 });
    if (!credential) {
      return res.status(428).json({
        success: false,
        message: "Admin password is not configured",
      });
    }

    if (credential.lockedUntil && credential.lockedUntil > new Date()) {
      return res.status(423).json({
        success: false,
        message: "Admin login is temporarily locked",
      });
    }

    const password = toText(req.body?.password);
    if (!password || !verifyPassword(password, credential)) {
      credential.failedAttempts += 1;
      if (credential.failedAttempts >= 5) {
        credential.lockedUntil = new Date(Date.now() + 15 * 60 * 1000);
      }
      await credential.save();
      await logSecurityEvent("admin_login_failed", "Admin login failed", req);
      return res.status(401).json({
        success: false,
        message: "Invalid admin password",
      });
    }

    credential.failedAttempts = 0;
    credential.lockedUntil = null;
    await credential.save();
    await logSecurityEvent("admin_login_success", "Admin login successful", req);

    return res.status(200).json({
      success: true,
      message: "Admin login successful",
      data: {
        ...passwordStatus(credential),
        sessionToken: createAdminSession(),
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to login admin",
      error: error.message,
    });
  }
};

export const changeAdminPassword = async (req, res) => {
  try {
    const credential = await AdminCredential.findOne().sort({ createdAt: 1 });
    if (!credential) {
      return res.status(428).json({
        success: false,
        message: "Admin password is not configured",
      });
    }

    const currentPassword = toText(req.body?.currentPassword);
    const newPassword = toText(req.body?.newPassword);
    const confirmPassword = toText(req.body?.confirmPassword);
    if (!currentPassword || !verifyPassword(currentPassword, credential)) {
      await logSecurityEvent("admin_password_change_failed", "Invalid current password", req);
      return res.status(401).json({
        success: false,
        message: "Current password is incorrect",
      });
    }
    if (!newPassword || newPassword.length < 8 || newPassword !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "New password must be at least 8 characters and match confirmation",
      });
    }

    const { hash, salt } = createPasswordHash(newPassword);
    credential.passwordHash = hash;
    credential.passwordSalt = salt;
    credential.lastChangedAt = new Date();
    credential.failedAttempts = 0;
    credential.lockedUntil = null;
    await credential.save();

    await logSecurityEvent("admin_password_changed", "Admin password changed", req);

    return res.status(200).json({
      success: true,
      message: "Admin password changed",
      data: passwordStatus(credential),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to change admin password",
      error: error.message,
    });
  }
};

export const resetAdminPassword = async (req, res) => {
  try {
    const credential = await AdminCredential.findOne().sort({ createdAt: 1 });
    if (!credential) {
      return res.status(428).json({
        success: false,
        message: "Admin password is not configured",
      });
    }
    if (credential.resetCount >= RESET_LIMIT) {
      return res.status(403).json({
        success: false,
        message: "Admin password reset limit reached",
      });
    }

    const newPassword = toText(req.body?.newPassword);
    const confirmPassword = toText(req.body?.confirmPassword);
    if (!newPassword || newPassword.length < 8 || newPassword !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "New password must be at least 8 characters and match confirmation",
      });
    }

    const { hash, salt } = createPasswordHash(newPassword);
    credential.passwordHash = hash;
    credential.passwordSalt = salt;
    credential.lastChangedAt = new Date();
    credential.resetCount += 1;
    credential.failedAttempts = 0;
    credential.lockedUntil = null;
    await credential.save();

    await logSecurityEvent("admin_password_reset", "Admin password reset", req, {
      resetCount: credential.resetCount,
    });

    return res.status(200).json({
      success: true,
      message: "Admin password reset",
      data: passwordStatus(credential),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to reset admin password",
      error: error.message,
    });
  }
};

export const getDevices = async (_req, res) => {
  try {
    const devices = await AuthorizedDevice.find()
      .sort({ updatedAt: -1, createdAt: -1 })
      .lean();
    return res.status(200).json({
      success: true,
      data: devices,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to load devices",
      error: error.message,
    });
  }
};

export const upsertCurrentDevice = async (req, res) => {
  try {
    const device = devicePayloadFromRequest(req);
    if (!device.installationId || !device.machineKey) {
      return res.status(428).json({
        success: false,
        message: "Installation id and machine key are required",
      });
    }

    let saved = await AuthorizedDevice.findOne({
      installationId: device.installationId,
      machineKey: device.machineKey,
    });

    if (saved) {
      saved.macAddress = device.macAddress;
      saved.ipAddress = device.ipAddress;
      saved.hostname = device.hostname;
      saved.appVersion = device.appVersion;
      saved.lastSeenAt = new Date();
      await saved.save();
    } else {
      saved = await AuthorizedDevice.create({
        ...device,
        status: "pending",
        lastSeenAt: new Date(),
      });
    }

    if (saved.status === "pending") {
      await logSecurityEvent("device_pending", "Device is pending approval", req);
    }

    return res.status(200).json({
      success: true,
      data: saved,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to register current device",
      error: error.message,
    });
  }
};

export const updateDeviceStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const status = toText(req.body?.status);
    if (!["allowed", "blocked", "pending"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid device status",
      });
    }

    const update = { status };
    if (status === "allowed") {
      update.approvedAt = new Date();
      update.blockedAt = null;
    } else if (status === "blocked") {
      update.blockedAt = new Date();
    }

    const device = await AuthorizedDevice.findByIdAndUpdate(id, update, {
      returnDocument: "after",
    });
    if (!device) {
      return res.status(404).json({
        success: false,
        message: "Device not found",
      });
    }

    await logSecurityEvent(
      `device_${status}`,
      `Device marked as ${status}`,
      req,
      { deviceId: id }
    );

    return res.status(200).json({
      success: true,
      message: `Device marked as ${status}`,
      data: device,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update device status",
      error: error.message,
    });
  }
};

export const deleteDevice = async (req, res) => {
  try {
    const deleted = await AuthorizedDevice.findByIdAndDelete(req.params.id);
    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: "Device not found",
      });
    }

    await logSecurityEvent("device_deleted", "Device deleted", req, {
      deviceId: req.params.id,
    });

    return res.status(200).json({
      success: true,
      message: "Device deleted",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete device",
      error: error.message,
    });
  }
};

export const getSecurityLogs = async (_req, res) => {
  try {
    const logs = await SecurityLog.find().sort({ createdAt: -1 }).limit(200).lean();
    return res.status(200).json({
      success: true,
      data: logs,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to load security logs",
      error: error.message,
    });
  }
};
