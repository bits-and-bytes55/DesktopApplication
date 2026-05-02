import Pit from "../../modules/pit/pit.model.js";

const toText = (value) => String(value ?? "").trim();

const legacyScopeFilter = (wellId) => ({
  wellId,
  $or: [{ reportId: { $exists: false } }, { reportId: null }, { reportId: "" }],
});

const exactScopeFilter = (wellId, reportId) =>
  reportId ? { wellId, reportId } : legacyScopeFilter(wellId);

const sortByCreatedAtAsc = (items = []) =>
  [...items].sort((left, right) => {
    const leftTime = new Date(left.createdAt ?? 0).getTime();
    const rightTime = new Date(right.createdAt ?? 0).getTime();
    return leftTime - rightTime;
  });

const dedupeLatestPits = (items = []) => {
  const latestByName = new Map();

  for (const item of items) {
    const key = toText(item.pitName).toLowerCase();
    if (!key || latestByName.has(key)) continue;
    latestByName.set(key, item);
  }

  return sortByCreatedAtAsc(Array.from(latestByName.values()));
};

const mergeScopedWithLegacy = (scopedItems = [], legacyItems = []) => {
  const merged = new Map();

  for (const item of dedupeLatestPits(legacyItems)) {
    const key = toText(item.pitName).toLowerCase();
    if (!key) continue;
    merged.set(key, item);
  }

  for (const item of sortByCreatedAtAsc(scopedItems)) {
    const key = toText(item.pitName).toLowerCase();
    if (!key) continue;
    merged.set(key, item);
  }

  return sortByCreatedAtAsc(Array.from(merged.values()));
};

const loadScopedPits = async ({ wellId, reportId, initialActive }) => {
  const scopedFilter = reportId ? { wellId, reportId } : { wellId };
  if (initialActive !== undefined) {
    scopedFilter.initialActive = initialActive;
  }

  if (reportId) {
    return Pit.find(scopedFilter).sort({ createdAt: 1, _id: 1 });
  }

  return Pit.find(scopedFilter).sort({ createdAt: 1, _id: 1 });
};

const clonePitForReport = async (pit, reportId, updates = {}) => {
  const nextPitName = toText(updates.pitName ?? pit.pitName);
  let scopedPit = await Pit.findOne({
    wellId: pit.wellId,
    reportId,
    pitName: nextPitName,
  }).sort({ createdAt: -1, _id: -1 });

  if (!scopedPit) {
    scopedPit = await Pit.create({
      pitName: nextPitName || toText(pit.pitName),
      capacity: Number(updates.capacity ?? pit.capacity) || 0,
      initialActive:
        updates.initialActive !== undefined
          ? Boolean(updates.initialActive)
          : Boolean(pit.initialActive),
      volume: Number(updates.volume ?? pit.volume) || 0,
      density: Number(updates.density ?? pit.density) || 0,
      fluidType: toText(updates.fluidType ?? pit.fluidType),
      wellId: toText(pit.wellId),
      reportId,
      isLocked:
        updates.isLocked !== undefined
          ? Boolean(updates.isLocked)
          : Boolean(pit.isLocked),
    });

    return scopedPit;
  }

  if (updates.pitName !== undefined) {
    scopedPit.pitName = nextPitName;
  }
  if (updates.capacity !== undefined) {
    scopedPit.capacity = Number(updates.capacity) || 0;
  }
  if (updates.initialActive !== undefined) {
    scopedPit.initialActive = Boolean(updates.initialActive);
  }
  if (updates.volume !== undefined) {
    scopedPit.volume = Number(updates.volume) || 0;
  }
  if (updates.density !== undefined) {
    scopedPit.density = Number(updates.density) || 0;
  }
  if (updates.fluidType !== undefined) {
    scopedPit.fluidType = toText(updates.fluidType);
  }
  if (updates.isLocked !== undefined) {
    scopedPit.isLocked = Boolean(updates.isLocked);
  }

  await scopedPit.save();
  return scopedPit;
};

// ============= CREATE OPERATIONS =============

export const addPit = async (req, res) => {
  try {
    const pitName = toText(req.body.pitName);
    const wellId = toText(req.body.wellId);
    const reportId = toText(req.body.reportId);
    const capacity = Number(req.body.capacity);

    if (!pitName) {
      return res.status(400).json({
        success: false,
        message: "Pit name is required",
      });
    }

    if (!Number.isFinite(capacity)) {
      return res.status(400).json({
        success: false,
        message: "Valid capacity is required",
      });
    }

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "Well ID is required",
      });
    }

    const existingPit = await Pit.findOne({
      ...exactScopeFilter(wellId, reportId),
      pitName,
      isLocked: false,
    });

    if (existingPit) {
      return res.status(409).json({
        success: false,
        message: "Pit with this name already exists for this well",
      });
    }

    const pit = new Pit({
      pitName,
      capacity,
      initialActive: Boolean(req.body.initialActive),
      volume: Number(req.body.volume) || 0,
      density: Number(req.body.density) || 0,
      fluidType: toText(req.body.fluidType),
      wellId,
      reportId,
      isLocked: false,
    });

    await pit.save();

    res.status(201).json({
      success: true,
      message: "Pit added successfully",
      data: pit,
    });
  } catch (error) {
    console.error("Add Pit Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to add pit",
      error: error.message,
    });
  }
};

export const bulkAddPits = async (req, res) => {
  try {
    const pits = Array.isArray(req.body.pits) ? req.body.pits : [];
    const wellId = toText(req.body.wellId);
    const reportId = toText(req.body.reportId);

    if (pits.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Pits array is required and cannot be empty",
      });
    }

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const pitNames = pits.map((pit) => toText(pit.pitName)).filter(Boolean);
    const existingPits = await Pit.find({
      ...exactScopeFilter(wellId, reportId),
      pitName: { $in: pitNames },
      isLocked: false,
    });

    const existingNames = new Set(
      existingPits.map((pit) => toText(pit.pitName).toLowerCase())
    );

    const newPits = pits
      .filter((pit) => !existingNames.has(toText(pit.pitName).toLowerCase()))
      .map((pit) => ({
        pitName: toText(pit.pitName),
        capacity: Number(pit.capacity) || 0,
        initialActive: Boolean(pit.initialActive),
        volume: Number(pit.volume) || 0,
        density: Number(pit.density) || 0,
        fluidType: toText(pit.fluidType),
        wellId,
        reportId: reportId || toText(pit.reportId),
        isLocked: false,
      }))
      .filter((pit) => pit.pitName);

    if (newPits.length === 0) {
      return res.status(409).json({
        success: false,
        message: "All pits already exist in the database",
      });
    }

    const insertedPits = await Pit.insertMany(newPits);

    res.status(201).json({
      success: true,
      message: `${insertedPits.length} pits added successfully`,
      data: insertedPits,
      skipped: pits.length - insertedPits.length,
    });
  } catch (error) {
    console.error("Bulk Add Pits Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to add pits",
      error: error.message,
    });
  }
};

// ============= READ OPERATIONS =============

export const getAllPits = async (req, res) => {
  try {
    const wellId = toText(req.params.wellId);
    const reportId = toText(req.query.reportId);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const pits = await loadScopedPits({ wellId, reportId });
    const totalCapacity = pits.reduce(
      (sum, pit) => sum + (Number(pit.capacity) || 0),
      0
    );

    res.status(200).json({
      success: true,
      data: pits,
      totalCapacity,
      count: pits.length,
    });
  } catch (error) {
    console.error("Get All Pits Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch pits",
      error: error.message,
    });
  }
};

export const getSelectedPits = async (req, res) => {
  try {
    const wellId = toText(req.params.wellId);
    const reportId = toText(req.query.reportId);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const selectedPits = await loadScopedPits({
      wellId,
      reportId,
      initialActive: true,
    });
    const totalCapacity = selectedPits.reduce(
      (sum, pit) => sum + (Number(pit.capacity) || 0),
      0
    );

    res.status(200).json({
      success: true,
      data: selectedPits,
      totalCapacity,
      count: selectedPits.length,
    });
  } catch (error) {
    console.error("Get Selected Pits Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch selected pits",
      error: error.message,
    });
  }
};

export const getUnselectedPits = async (req, res) => {
  try {
    const wellId = toText(req.params.wellId);
    const reportId = toText(req.query.reportId);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const unselectedPits = await loadScopedPits({
      wellId,
      reportId,
      initialActive: false,
    });
    const totalCapacity = unselectedPits.reduce(
      (sum, pit) => sum + (Number(pit.capacity) || 0),
      0
    );

    res.status(200).json({
      success: true,
      data: unselectedPits,
      totalCapacity,
      count: unselectedPits.length,
    });
  } catch (error) {
    console.error("Get Unselected Pits Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch unselected pits",
      error: error.message,
    });
  }
};

export const getPitById = async (req, res) => {
  try {
    const { id } = req.params;

    const pit = await Pit.findById(id);

    if (!pit) {
      return res.status(404).json({
        success: false,
        message: "Pit not found",
      });
    }

    res.status(200).json({
      success: true,
      data: pit,
    });
  } catch (error) {
    console.error("Get Pit By ID Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch pit",
      error: error.message,
    });
  }
};

// ============= UPDATE OPERATIONS =============

export const updatePit = async (req, res) => {
  try {
    const { id } = req.params;
    const reportId = toText(req.body.reportId ?? req.query.reportId);
    const pit = await Pit.findById(id);

    if (!pit) {
      return res.status(404).json({
        success: false,
        message: "Pit not found",
      });
    }

    if (pit.isLocked) {
      return res.status(403).json({
        success: false,
        message: "Cannot update locked pit",
      });
    }

    if (reportId && toText(pit.reportId) !== reportId) {
      return res.status(404).json({
        success: false,
        message: "Pit not found for this report",
      });
    }

    if (req.body.pitName !== undefined) {
      pit.pitName = toText(req.body.pitName);
    }
    if (req.body.capacity !== undefined) {
      pit.capacity = Number(req.body.capacity) || 0;
    }
    if (req.body.initialActive !== undefined) {
      pit.initialActive = Boolean(req.body.initialActive);
    }
    if (req.body.volume !== undefined) {
      pit.volume = Number(req.body.volume) || 0;
    }
    if (req.body.density !== undefined) {
      pit.density = Number(req.body.density) || 0;
    }
    if (req.body.fluidType !== undefined) {
      pit.fluidType = toText(req.body.fluidType);
    }
    if (req.body.reportId !== undefined) {
      pit.reportId = reportId;
    }

    await pit.save();

    res.status(200).json({
      success: true,
      message: "Pit updated successfully",
      data: pit,
    });
  } catch (error) {
    console.error("Update Pit Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update pit",
      error: error.message,
    });
  }
};

export const bulkUpdatePits = async (req, res) => {
  try {
    const updates = Array.isArray(req.body.updates) ? req.body.updates : [];

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Updates array is required and cannot be empty",
      });
    }

    const bulkOps = updates.map((update) => ({
      updateOne: {
        filter: { _id: update.id, isLocked: false },
        update: {
          $set: {
            ...(update.pitName && { pitName: toText(update.pitName) }),
            ...(update.capacity !== undefined && {
              capacity: Number(update.capacity) || 0,
            }),
            ...(update.initialActive !== undefined && {
              initialActive: Boolean(update.initialActive),
            }),
            ...(update.volume !== undefined && {
              volume: Number(update.volume) || 0,
            }),
            ...(update.density !== undefined && {
              density: Number(update.density) || 0,
            }),
            ...(update.fluidType !== undefined && {
              fluidType: toText(update.fluidType),
            }),
            ...(update.reportId !== undefined && {
              reportId: toText(update.reportId),
            }),
            updatedAt: Date.now(),
          },
        },
      },
    }));

    const result = await Pit.bulkWrite(bulkOps);

    res.status(200).json({
      success: true,
      message: "Pits updated successfully",
      modifiedCount: result.modifiedCount,
    });
  } catch (error) {
    console.error("Bulk Update Pits Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update pits",
      error: error.message,
    });
  }
};

export const toggleLockPit = async (req, res) => {
  try {
    const { id } = req.params;
    const pit = await Pit.findById(id);

    if (!pit) {
      return res.status(404).json({
        success: false,
        message: "Pit not found",
      });
    }

    pit.isLocked =
      req.body.isLocked !== undefined ? Boolean(req.body.isLocked) : !pit.isLocked;
    await pit.save();

    res.status(200).json({
      success: true,
      message: `Pit ${pit.isLocked ? "locked" : "unlocked"} successfully`,
      data: pit,
    });
  } catch (error) {
    console.error("Toggle Lock Pit Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to toggle pit lock",
      error: error.message,
    });
  }
};

// ============= DELETE OPERATIONS =============

export const deletePit = async (req, res) => {
  try {
    const { id } = req.params;
    const reportId = toText(req.query.reportId ?? req.body?.reportId);

    const pit = await Pit.findById(id);

    if (!pit) {
      return res.status(404).json({
        success: false,
        message: "Pit not found",
      });
    }

    if (pit.isLocked) {
      return res.status(403).json({
        success: false,
        message: "Cannot delete locked pit",
      });
    }

    if (reportId && toText(pit.reportId) !== reportId) {
      return res.status(404).json({
        success: false,
        message: "Pit not found for this report",
      });
    }

    await Pit.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: "Pit deleted successfully",
    });
  } catch (error) {
    console.error("Delete Pit Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete pit",
      error: error.message,
    });
  }
};

export const bulkDeletePits = async (req, res) => {
  try {
    const ids = Array.isArray(req.body.ids) ? req.body.ids : [];

    if (ids.length === 0) {
      return res.status(400).json({
        success: false,
        message: "IDs array is required and cannot be empty",
      });
    }

    const result = await Pit.deleteMany({
      _id: { $in: ids },
      isLocked: false,
    });

    res.status(200).json({
      success: true,
      message: `${result.deletedCount} pits deleted successfully`,
      deletedCount: result.deletedCount,
    });
  } catch (error) {
    console.error("Bulk Delete Pits Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete pits",
      error: error.message,
    });
  }
};

export const deleteAllPitsByWell = async (req, res) => {
  try {
    const wellId = toText(req.params.wellId);
    const reportId = toText(req.query.reportId);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const filter = reportId ? { wellId, reportId, isLocked: false } : { wellId, isLocked: false };
    const result = await Pit.deleteMany(filter);

    res.status(200).json({
      success: true,
      message: `${result.deletedCount} pits deleted successfully`,
      deletedCount: result.deletedCount,
    });
  } catch (error) {
    console.error("Delete All Pits Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete pits",
      error: error.message,
    });
  }
};
