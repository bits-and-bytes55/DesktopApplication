import Pit from "../../modules/pit/pit.model.js";

const getWellId = (req) => String(req.params.wellId || "").trim();

const normalizeNames = (arr) => {
  return Array.isArray(arr)
    ? arr.map((name) => String(name).trim()).filter(Boolean)
    : [];
};

const mapPit = (pit) => ({
  _id: pit._id,
  pitName: pit.pitName,
  volume: pit.volume || 0,
  density: pit.density || 0,
  fluidType: pit.fluidType || "",
  initialActive: pit.initialActive,
});

const getPitSummary = async (wellId) => {
  const activePits = await Pit.find({
    wellId,
    initialActive: true,
  }).sort({ createdAt: 1 });

  const storagePits = await Pit.find({
    wellId,
    initialActive: false,
  }).sort({ createdAt: 1 });

  return {
    activePits: activePits.map(mapPit),
    storagePits: storagePits.map(mapPit),
  };
};

export const movePitStatus = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { moveToStorage = [], moveToActive = [] } = req.body;

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const activeToStorage = normalizeNames(moveToStorage);
    const storageToActive = normalizeNames(moveToActive);

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

    for (const pitName of activeToStorage) {
      const pit = await Pit.findOne({
        wellId,
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

    for (const pitName of storageToActive) {
      const pit = await Pit.findOne({
        wellId,
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

    const summary = await getPitSummary(wellId);

    return res.status(200).json({
      success: true,
      message: "Pit status updated successfully",
      data: {
        wellId,
        ...updated,
        ...summary,
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

export const getPitStatusList = async (req, res) => {
  try {
    const wellId = getWellId(req);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const pits = await Pit.find({ wellId }).sort({ createdAt: 1 });

    if (!pits.length) {
      return res.status(404).json({
        success: false,
        message: "No pits found for this wellId",
      });
    }

    const summary = await getPitSummary(wellId);

    return res.status(200).json({
      success: true,
      count: pits.length,
      data: {
        wellId,
        allPits: pits.map(mapPit),
        ...summary,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch pit status list",
      error: error.message,
    });
  }
};

export const getPitStatusById = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;

    const pit = await Pit.findOne({ _id: id, wellId });

    if (!pit) {
      return res.status(404).json({
        success: false,
        message: "Pit not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: mapPit(pit),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch pit",
      error: error.message,
    });
  }
};

export const updateSinglePitStatus = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;
    const { moveTo } = req.body;

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    if (!moveTo || !["Active", "Storage"].includes(String(moveTo).trim())) {
      return res.status(400).json({
        success: false,
        message: "moveTo must be either 'Active' or 'Storage'",
      });
    }

    const pit = await Pit.findOne({ _id: id, wellId });

    if (!pit) {
      return res.status(404).json({
        success: false,
        message: "Pit not found",
      });
    }

    const targetStatus = String(moveTo).trim() === "Active";

    pit.initialActive = targetStatus;
    await pit.save();

    const summary = await getPitSummary(wellId);

    return res.status(200).json({
      success: true,
      message: `Pit moved to ${moveTo} successfully`,
      data: {
        updatedPit: mapPit(pit),
        ...summary,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update pit status",
      error: error.message,
    });
  }
};