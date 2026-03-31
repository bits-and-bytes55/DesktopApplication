import Pit from "../../modules/pit/pit.model.js";

export const movePitStatus = async (req, res) => {
  try {
    const { wellId, moveToStorage = [], moveToActive = [] } = req.body;

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const safeWellId = String(wellId).trim();

    const activeToStorage = Array.isArray(moveToStorage)
      ? moveToStorage.map((name) => String(name).trim()).filter(Boolean)
      : [];

    const storageToActive = Array.isArray(moveToActive)
      ? moveToActive.map((name) => String(name).trim()).filter(Boolean)
      : [];

    if (activeToStorage.length === 0 && storageToActive.length === 0) {
      return res.status(400).json({
        success: false,
        message: "At least one pit must be selected",
      });
    }

    const updated = {
      movedToStorage: [],
      movedToActive: [],
      notFound: [],
    };

    // Active -> Storage
    for (const pitName of activeToStorage) {
      const pit = await Pit.findOne({
        wellId: safeWellId,
        pitName,
        initialActive: true,
      });

      if (!pit) {
        updated.notFound.push({
          pitName,
          expectedFrom: "Active",
          moveTo: "Storage",
        });
        continue;
      }

      pit.initialActive = false;
      await pit.save();

      updated.movedToStorage.push({
        pitName: pit.pitName,
        volume: pit.volume || 0,
      });
    }

    // Storage -> Active
    for (const pitName of storageToActive) {
      const pit = await Pit.findOne({
        wellId: safeWellId,
        pitName,
        initialActive: false,
      });

      if (!pit) {
        updated.notFound.push({
          pitName,
          expectedFrom: "Storage",
          moveTo: "Active",
        });
        continue;
      }

      pit.initialActive = true;
      await pit.save();

      updated.movedToActive.push({
        pitName: pit.pitName,
        volume: pit.volume || 0,
      });
    }

    const activePits = await Pit.find({
      wellId: safeWellId,
      initialActive: true,
    }).sort({ createdAt: 1 });

    const storagePits = await Pit.find({
      wellId: safeWellId,
      initialActive: false,
    }).sort({ createdAt: 1 });

    return res.status(200).json({
      success: true,
      message: "Pit status updated successfully",
      data: {
        wellId: safeWellId,
        ...updated,
        activePits: activePits.map((pit) => ({
          _id: pit._id,
          pitName: pit.pitName,
          volume: pit.volume || 0,
          density: pit.density || 0,
          fluidType: pit.fluidType || "",
        })),
        storagePits: storagePits.map((pit) => ({
          _id: pit._id,
          pitName: pit.pitName,
          volume: pit.volume || 0,
          density: pit.density || 0,
          fluidType: pit.fluidType || "",
        })),
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to move pit status",
      error: error.message,
    });
  }
};