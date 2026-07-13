import AuthorizedDevice from "../../modules/adminControl/authorizedDevice.model.js";

export const requireAuthorizedDevice = async (req, res, next) => {
  try {
    if (req.method === "OPTIONS") {
      return next();
    }

    const installationId = String(req.installationId ?? "").trim();
    const machineKey = String(req.machineKey ?? "").trim();
    if (!installationId || !machineKey) {
      return res.status(428).json({
        success: false,
        message: "Installation id and machine key are required",
      });
    }

    const device = await AuthorizedDevice.findOne({
      installationId,
      machineKey,
    });

    if (!device || device.status !== "allowed") {
      return res.status(403).json({
        success: false,
        code: "DEVICE_NOT_AUTHORIZED",
        message:
          device?.status === "expired"
            ? "This device access has expired. Please contact admin."
            : "This device is not authorized. Open Admin Control.",
      });
    }

    const expiresAt = device.accessExpiresAt ? new Date(device.accessExpiresAt) : null;
    if (
      device.accessType === "timed" &&
      expiresAt &&
      expiresAt.getTime() <= Date.now()
    ) {
      device.status = "expired";
      device.lastAccessCheckAt = new Date();
      await device.save();
      return res.status(403).json({
        success: false,
        code: "DEVICE_ACCESS_EXPIRED",
        message: "This device access has expired. Please contact admin.",
      });
    }

    device.lastAccessCheckAt = new Date();
    await device.save();

    return next();
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to verify device authorization",
      error: error.message,
    });
  }
};
