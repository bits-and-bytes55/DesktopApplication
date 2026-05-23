import Pit from "../../modules/pit/pit.model.js";
import MudLossStorage from "../../modules/mudlossstorage/MudLossStorage.js";
import { findWritablePitByName } from "../../utils/pitReportState.js";
import { buildScopedFilter, readReportId } from "../../utils/reportScope.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));
const getWellId = (req) => String(req.params.wellId || "").trim();

const prepareMudLossStorageData = (wellId, reportId, payload = {}) => {
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
    reportId,
    operationInstanceKey: String(payload.operationInstanceKey || "").trim(),
    storage: safeStorage,
    dump: dumpVol,
    evaporation: evaporationVol,
    pitCleaning: pitCleaningVol,
    totalLoss,
  };
};

const deductFromStoragePit = async ({ wellId, reportId, storage, totalLoss }) => {
  return;
};

const revertToStoragePit = async ({ wellId, reportId, storage, totalLoss }) => {
  return;
};

export const createMudLossStorage = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const payloads = Array.isArray(req.body) ? req.body : [req.body];

    if (!payloads.length) {
      return res.status(400).json({
        success: false,
        message: "Request body is empty",
      });
    }

    const createdItems = [];

    for (const payload of payloads) {
      const prepared = prepareMudLossStorageData(wellId, reportId, payload);

      await deductFromStoragePit({
        wellId: prepared.wellId,
        reportId: prepared.reportId,
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
    const reportId = readReportId(req);

    const items = await MudLossStorage.find(
      buildScopedFilter(wellId, reportId)
    ).sort({ createdAt: -1 });

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
    const reportId = readReportId(req);
    const { id } = req.params;

    const item = await MudLossStorage.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

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
    const reportId = readReportId(req);
    const { id } = req.params;

    const existing = await MudLossStorage.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Mud Loss - Storage record not found",
      });
    }

    await revertToStoragePit({
      wellId,
      reportId,
      storage: existing.storage,
      totalLoss: toNumber(existing.totalLoss),
    });

    const mergedPayload = {
      storage: req.body.storage ?? existing.storage,
      dump: req.body.dump ?? existing.dump,
      evaporation: req.body.evaporation ?? existing.evaporation,
      pitCleaning: req.body.pitCleaning ?? existing.pitCleaning,
      operationInstanceKey:
        req.body.operationInstanceKey ?? existing.operationInstanceKey ?? "",
    };

    const prepared = prepareMudLossStorageData(wellId, reportId, mergedPayload);

    await deductFromStoragePit({
      wellId: prepared.wellId,
      reportId: prepared.reportId,
      storage: prepared.storage,
      totalLoss: prepared.totalLoss,
    });

    existing.storage = prepared.storage;
    existing.dump = prepared.dump;
    existing.evaporation = prepared.evaporation;
    existing.pitCleaning = prepared.pitCleaning;
    existing.totalLoss = prepared.totalLoss;
    existing.reportId = prepared.reportId;
    existing.operationInstanceKey = prepared.operationInstanceKey;

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
    const reportId = readReportId(req);
    const { id } = req.params;

    const existing = await MudLossStorage.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Mud Loss - Storage record not found",
      });
    }

    await revertToStoragePit({
      wellId,
      reportId,
      storage: existing.storage,
      totalLoss: toNumber(existing.totalLoss),
    });

    await MudLossStorage.deleteOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

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
