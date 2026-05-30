import InstallationDevice from "../modules/installation/installationDevice.model.js";

export const verifyInstallationMachine = async (req, res, next) => {
  try {
    const { installationId, machineKey } = req;

    let device = await InstallationDevice.findOne({ installationId });

    if (!device) {
      device = await InstallationDevice.create({
        installationId,
        machineKey,
        firstSeenAt: new Date(),
        lastSeenAt: new Date(),
      });
      return next();
    }

    if (device.machineKey !== machineKey) {
      return res.status(403).json({
        success: false,
        message: "System mismatch. This installation belongs to another system.",
      });
    }

    device.lastSeenAt = new Date();
    await device.save();
    return next();
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to verify installation system",
      error: error.message,
    });
  }
};
