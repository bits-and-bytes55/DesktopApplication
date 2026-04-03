import Pit from "../../modules/pit/pit.model.js";
import MudLossStorage from "../../modules/mudlossstorage/MudLossStorage.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));
const getWellId = (req) => String(req.params.wellId || "").trim();

const prepareMudLossStorageData = (wellId, payload = {}) => {
  const { storage, dump, evaporation, pitCleaning } = payload;

  if (!wellId || !storage) {
    throw new Error("wellId and storage are required");
  }

  const safeStorage = String(storage).trim();

  const dumpVol = round2(toNumber(dump));
  const evaporationVol = round2(toNumber(evaporation));
  const pitCleaningVol = round2(toNumber(pitCleaning));

  const totalLoss = round2(dumpVol + evaporationVol + pitCleaningVol);

  if (totalLoss <= 0) {
    throw new Error("At least one storage mud loss value must be greater than 0");
  }

  return {
    wellId,
    storage: safeStorage,
    dump: dumpVol,
    evaporation: evaporationVol,
    pitCleaning: pitCleaningVol,
    totalLoss,
  };
};

const deductFromStoragePit = async ({ wellId, storage, totalLoss }) => {
  const sourcePit = await Pit.findOne({
    wellId,
    pitName: String(storage).trim(),
    initialActive: false,
  });

  if (!sourcePit) {
    throw new Error(`Storage pit '${storage}' not found`);
  }

  const currentVol = round2(toNumber(sourcePit.volume));

  if (totalLoss > currentVol) {
    throw new Error(
      `Mud loss (${totalLoss}) exceeds storage pit volume (${currentVol})`
    );
  }

  sourcePit.volume = round2(currentVol - totalLoss);
  await sourcePit.save();
};

const revertToStoragePit = async ({ wellId, storage, totalLoss }) => {
  if (totalLoss <= 0) return;

  const sourcePit = await Pit.findOne({
    wellId,
    pitName: String(storage).trim(),
    initialActive: false,
  });

  if (!sourcePit) {
    throw new Error(`Storage pit '${storage}' not found`);
  }

  sourcePit.volume = round2(toNumber(sourcePit.volume) + totalLoss);
  await sourcePit.save();
};

export const createMudLossStorage = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const payloads = Array.isArray(req.body) ? req.body : [req.body];

    if (!payloads.length) {
      return res.status(400).json({
        success: false,
        message: "Request body is empty",
      });
    }

    const createdItems = [];

    for (const payload of payloads) {
      const prepared = prepareMudLossStorageData(wellId, payload);

      await deductFromStoragePit({
        wellId: prepared.wellId,
        storage: prepared.storage,
        totalLoss: prepared.totalLoss,
      });

      const item = await MudLossStorage.create(prepared);
      createdItems.push(item);
    }

    return res.status(201).json({
      success: true,
      message:
        createdItems.length === 1
          ? "Mud Loss - Storage saved successfully"
          : "Multiple Mud Loss - Storage records saved successfully",
      count: createdItems.length,
      data: createdItems,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to save Mud Loss - Storage",
      error: error.message,
    });
  }
};

export const getMudLossStorageList = async (req, res) => {
  try {
    const wellId = getWellId(req);

    const items = await MudLossStorage.find({ wellId }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: items.length,
      data: items,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Mud Loss - Storage records",
      error: error.message,
    });
  }
};

export const getMudLossStorageById = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;

    const item = await MudLossStorage.findOne({ _id: id, wellId });

    if (!item) {
      return res.status(404).json({
        success: false,
        message: "Mud Loss - Storage record not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Mud Loss - Storage record",
      error: error.message,
    });
  }
};

export const updateMudLossStorage = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;

    const existing = await MudLossStorage.findOne({ _id: id, wellId });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Mud Loss - Storage record not found",
      });
    }

    await revertToStoragePit({
      wellId,
      storage: existing.storage,
      totalLoss: toNumber(existing.totalLoss),
    });

    const mergedPayload = {
      storage: req.body.storage ?? existing.storage,
      dump: req.body.dump ?? existing.dump,
      evaporation: req.body.evaporation ?? existing.evaporation,
      pitCleaning: req.body.pitCleaning ?? existing.pitCleaning,
    };

    const prepared = prepareMudLossStorageData(wellId, mergedPayload);

    await deductFromStoragePit({
      wellId: prepared.wellId,
      storage: prepared.storage,
      totalLoss: prepared.totalLoss,
    });

    existing.storage = prepared.storage;
    existing.dump = prepared.dump;
    existing.evaporation = prepared.evaporation;
    existing.pitCleaning = prepared.pitCleaning;
    existing.totalLoss = prepared.totalLoss;

    await existing.save();

    return res.status(200).json({
      success: true,
      message: "Mud Loss - Storage updated successfully",
      data: existing,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update Mud Loss - Storage",
      error: error.message,
    });
  }
};

export const deleteMudLossStorage = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;

    const existing = await MudLossStorage.findOne({ _id: id, wellId });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Mud Loss - Storage record not found",
      });
    }

    await revertToStoragePit({
      wellId,
      storage: existing.storage,
      totalLoss: toNumber(existing.totalLoss),
    });

    await MudLossStorage.deleteOne({ _id: id, wellId });

    return res.status(200).json({
      success: true,
      message: "Mud Loss - Storage deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete Mud Loss - Storage",
      error: error.message,
    });
  }
};