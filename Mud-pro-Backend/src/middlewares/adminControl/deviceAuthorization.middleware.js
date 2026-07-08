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
    }).lean();

    if (!device || device.status !== "allowed") {
      return res.status(403).json({
        success: false,
        code: "DEVICE_NOT_AUTHORIZED",
        message: "This device is not authorized. Open Admin Control.",
      });
    }

    return next();
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to verify device authorization",
      error: error.message,
    });
  }
};
