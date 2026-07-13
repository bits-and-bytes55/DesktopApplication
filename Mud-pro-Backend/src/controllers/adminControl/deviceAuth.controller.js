import crypto from "node:crypto";
import AccessCode from "../../modules/adminControl/accessCode.model.js";
import AuthorizedDevice from "../../modules/adminControl/authorizedDevice.model.js";
import SecurityLog from "../../modules/adminControl/securityLog.model.js";

const toText = (value) => String(value ?? "").trim();

const devicePayloadFromRequest = (req) => ({
  installationId: toText(req.installationId),
  machineKey: toText(req.machineKey),
  macAddress: toText(req.body?.macAddress),
  ipAddress: toText(req.body?.ipAddress) || toText(req.ip),
  hostname: toText(req.body?.hostname),
  appVersion: toText(req.body?.appVersion),
});

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

const hashAccessCode = (code) =>
  crypto.createHash("sha256").update(String(code)).digest("hex");

const applyDeviceExpiry = async (device) => {
  if (!device) return device;
  const expiresAt = device.accessExpiresAt ? new Date(device.accessExpiresAt) : null;
  const expired =
    device.status === "allowed" &&
    device.accessType === "timed" &&
    expiresAt &&
    expiresAt.getTime() <= Date.now();

  device.lastAccessCheckAt = new Date();
  if (expired) {
    device.status = "expired";
    await logSecurityEvent("device_access_expired", "Device timed access expired", {
      ...devicePayloadFromDevice(device),
      body: {},
      ip: device.ipAddress,
    });
  }
  await device.save();
  return device;
};

const devicePayloadFromDevice = (device) => ({
  installationId: toText(device?.installationId),
  machineKey: toText(device?.machineKey),
  body: {
    macAddress: toText(device?.macAddress),
    ipAddress: toText(device?.ipAddress),
    hostname: toText(device?.hostname),
    appVersion: toText(device?.appVersion),
  },
  ip: toText(device?.ipAddress),
});

export const checkDeviceAccess = async (req, res) => {
  try {
    const device = devicePayloadFromRequest(req);
    if (!device.installationId || !device.machineKey) {
      return res.status(428).json({
        success: false,
        allowed: false,
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

    saved = await applyDeviceExpiry(saved);

    const allowed = saved.status === "allowed";
    if (!allowed) {
      await logSecurityEvent(
        "device_access_blocked",
        `Device access ${saved.status}`,
        req,
        { status: saved.status, deviceId: String(saved._id) }
      );
    }

    return res.status(200).json({
      success: true,
      allowed,
      message: allowed
        ? "Device access allowed"
        : saved.status === "expired"
          ? "This device access has expired. Please contact admin."
          : "This device is not authorized. Login to Admin Control to approve this device.",
      data: saved,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      allowed: false,
      message: "Failed to check device access",
      error: error.message,
    });
  }
};

export const verifyAccessCode = async (req, res) => {
  try {
    const device = devicePayloadFromRequest(req);
    const code = toText(req.body?.code).replace(/\D/g, "");
    if (!device.installationId || !device.machineKey) {
      return res.status(428).json({
        success: false,
        allowed: false,
        message: "Installation id and machine key are required",
      });
    }
    if (code.length !== 10) {
      return res.status(400).json({
        success: false,
        allowed: false,
        message: "Enter a valid 10 digit access code",
      });
    }

    let saved = await AuthorizedDevice.findOne({
      installationId: device.installationId,
      machineKey: device.machineKey,
    });

    if (!saved) {
      saved = await AuthorizedDevice.create({
        ...device,
        status: "pending",
        lastSeenAt: new Date(),
      });
    }

    if (saved.status === "blocked") {
      return res.status(403).json({
        success: false,
        allowed: false,
        message: "This device is blocked. Please contact admin.",
      });
    }

    const accessCode = await AccessCode.findOne({
      codeHash: hashAccessCode(code),
      installationId: device.installationId,
      machineKey: device.machineKey,
      usedAt: null,
    });

    if (!accessCode) {
      await logSecurityEvent("access_code_invalid", "Invalid access code entered", req);
      return res.status(401).json({
        success: false,
        allowed: false,
        message: "Invalid access code",
      });
    }

    if (new Date(accessCode.codeExpiresAt).getTime() <= Date.now()) {
      await logSecurityEvent("access_code_expired", "Expired access code entered", req, {
        codeLast4: accessCode.codeLast4,
      });
      return res.status(410).json({
        success: false,
        allowed: false,
        message: "Access code expired. Please contact admin.",
      });
    }

    const now = new Date();
    const accessExpiresAt = new Date(
      now.getTime() + accessCode.durationDays * 24 * 60 * 60 * 1000
    );
    accessCode.usedAt = now;
    accessCode.usedByInstallationId = device.installationId;
    accessCode.usedByMachineKey = device.machineKey;
    accessCode.accessStartsAt = now;
    accessCode.accessExpiresAt = accessExpiresAt;
    await accessCode.save();

    saved.macAddress = device.macAddress;
    saved.ipAddress = device.ipAddress;
    saved.hostname = device.hostname;
    saved.appVersion = device.appVersion;
    saved.status = "allowed";
    saved.accessType = "timed";
    saved.accessStartsAt = now;
    saved.accessExpiresAt = accessExpiresAt;
    saved.accessDurationDays = accessCode.durationDays;
    saved.approvedAt = now;
    saved.blockedAt = null;
    saved.lastSeenAt = now;
    saved.lastAccessCheckAt = now;
    await saved.save();

    await logSecurityEvent("access_code_used", "Timed access code activated", req, {
      deviceId: String(saved._id),
      durationDays: accessCode.durationDays,
      codeLast4: accessCode.codeLast4,
      accessExpiresAt,
    });

    return res.status(200).json({
      success: true,
      allowed: true,
      message: "Device access activated",
      data: saved,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      allowed: false,
      message: "Failed to verify access code",
      error: error.message,
    });
  }
};
