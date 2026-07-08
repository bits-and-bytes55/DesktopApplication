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
