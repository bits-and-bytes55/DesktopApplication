import Pit from "../../modules/pit/pit.model.js";
import MudLossStorage from "../../modules/mudlossstorage/MudLossStorage.js";
import { buildScopedFilter, readReportId } from "../../utils/reportScope.js";
import { calculateTransferSourceBalanceForReport } from "../pitvolumename/volumeName.controller.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));
const getWellId = (req) => String(req.params.wellId || "").trim();
const normalizeText = (value) => String(value ?? "").trim();
const normalizeKeyText = (value) => normalizeText(value).toLowerCase();
const makeValidationError = (message) => {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
};

const prepareMudLossStorageData = (wellId, reportId, payload = {}) => {
  const { storage, dump, evaporation, pitCleaning } = payload;

  if (!wellId || !storage) {
    throw makeValidationError("wellId and storage are required");
  }

  const safeStorage = String(storage).trim();

  const dumpVol = round2(toNumber(dump));
  const evaporationVol = round2(toNumber(evaporation));
  const pitCleaningVol = round2(toNumber(pitCleaning));

  const totalLoss = round2(dumpVol + evaporationVol + pitCleaningVol);

  if (totalLoss <= 0) {
    throw makeValidationError(
      "At least one storage mud loss value must be greater than 0"
    );
  }

  return {
    wellId,
    reportId,
    operationInstanceKey: String(payload.operationInstanceKey || "").trim(),
    rowNumber: Number(payload.rowNumber) || 0,
    storage: safeStorage,
    dump: dumpVol,
    evaporation: evaporationVol,
    pitCleaning: pitCleaningVol,
    totalLoss,
  };
};

const mudLossStorageLogicalKey = (item = {}) => {
  const operationInstanceKey = normalizeText(item.operationInstanceKey);
  const rowNumber = Number(item.rowNumber) || 0;
  if (operationInstanceKey && rowNumber > 0) {
    return `${operationInstanceKey}::row:${rowNumber}`;
  }

  const storage = normalizeKeyText(item.storage);
  if (operationInstanceKey && storage) {
    return `${operationInstanceKey}::legacy:${storage}`;
  }

  return String(item._id || item.id || "");
};

const itemTime = (item = {}) =>
  new Date(item.updatedAt || item.createdAt || 0).getTime();

const normalizeMudLossStorageItems = (items = []) => {
  const latestByKey = new Map();

  for (const item of items) {
    const key = mudLossStorageLogicalKey(item);
    if (!key) continue;
    const existing = latestByKey.get(key);
    if (!existing || itemTime(item) >= itemTime(existing)) {
      latestByKey.set(key, item);
    }
  }

  const rowBasedStorageKeys = new Set();
  for (const item of latestByKey.values()) {
    const operationInstanceKey = normalizeText(item.operationInstanceKey);
    const rowNumber = Number(item.rowNumber) || 0;
    const storage = normalizeKeyText(item.storage);
    if (operationInstanceKey && rowNumber > 0 && storage) {
      rowBasedStorageKeys.add(`${operationInstanceKey}::${storage}`);
    }
  }

  return Array.from(latestByKey.values())
    .filter((item) => {
      const operationInstanceKey = normalizeText(item.operationInstanceKey);
      const rowNumber = Number(item.rowNumber) || 0;
      const storage = normalizeKeyText(item.storage);
      if (!operationInstanceKey || rowNumber > 0 || !storage) return true;
      return !rowBasedStorageKeys.has(`${operationInstanceKey}::${storage}`);
    })
    .sort((left, right) => {
      const leftRow = Number(left.rowNumber) || 0;
      const rightRow = Number(right.rowNumber) || 0;
      if (leftRow !== rightRow) return leftRow - rightRow;
      return itemTime(right) - itemTime(left);
    });
};

const storagePitFilter = ({ wellId, reportId, storage }) => ({
  ...buildScopedFilter(wellId, reportId, {
    pitName: storage,
    initialActive: false,
  }),
});

const assertStorageHasAvailableVolume = async ({
  wellId,
  reportId,
  storage,
  totalLoss,
  excludeId = "",
}) => {
  const pit = await Pit.findOne(
    storagePitFilter({ wellId, reportId, storage })
  ).sort({ createdAt: -1, _id: -1 });

  if (!pit) {
    throw makeValidationError(`Storage ${storage} was not found`);
  }

  const excludeRecordId =
    typeof excludeId === "object" ? excludeId.id || "" : excludeId;
  const available = Math.max(
    0,
    round2(
      await calculateTransferSourceBalanceForReport({
        wellId,
        reportId,
        source: storage,
        excludeMudLossStorageId: excludeRecordId,
      })
    )
  );

  if (available <= 0) {
    throw makeValidationError(`Storage ${storage} has no available volume`);
  }

  if (toNumber(totalLoss) > available + 0.005) {
    throw makeValidationError(
      `Storage ${storage} loss ${toNumber(totalLoss).toFixed(2)} bbl exceeds ` +
        `available volume ${available.toFixed(2)} bbl`
    );
  }
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
      const logicalKey = mudLossStorageLogicalKey(prepared);
      const existing =
        prepared.operationInstanceKey && prepared.rowNumber > 0
          ? await MudLossStorage.findOne(
              buildScopedFilter(wellId, reportId, {
                operationInstanceKey: prepared.operationInstanceKey,
                rowNumber: prepared.rowNumber,
              })
            ).sort({ updatedAt: -1, createdAt: -1, _id: -1 })
          : null;

      await assertStorageHasAvailableVolume({
        wellId: prepared.wellId,
        reportId: prepared.reportId,
        storage: prepared.storage,
        totalLoss: prepared.totalLoss,
        excludeId: existing
          ? { id: existing._id, logicalKey }
          : { logicalKey },
      });

      await deductFromStoragePit({
        wellId: prepared.wellId,
        reportId: prepared.reportId,
        storage: prepared.storage,
        totalLoss: prepared.totalLoss,
      });

      let item = existing;
      if (item) {
        item.storage = prepared.storage;
        item.dump = prepared.dump;
        item.evaporation = prepared.evaporation;
        item.pitCleaning = prepared.pitCleaning;
        item.totalLoss = prepared.totalLoss;
        item.reportId = prepared.reportId;
        item.operationInstanceKey = prepared.operationInstanceKey;
        item.rowNumber = prepared.rowNumber;
        await item.save();
      } else {
        item = await MudLossStorage.create(prepared);
      }
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
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      success: false,
      message: error.statusCode
        ? error.message
        : "Failed to save Mud Loss - Storage",
      error: error.message,
    });
  }
};

export const getMudLossStorageList = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);

    const items = normalizeMudLossStorageItems(await MudLossStorage.find(
      buildScopedFilter(wellId, reportId)
    ).sort({ createdAt: -1 }).lean());

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
      rowNumber: req.body.rowNumber ?? existing.rowNumber ?? 0,
    };

    const prepared = prepareMudLossStorageData(wellId, reportId, mergedPayload);
    const logicalKey = mudLossStorageLogicalKey(prepared);

    await assertStorageHasAvailableVolume({
      wellId: prepared.wellId,
      reportId: prepared.reportId,
      storage: prepared.storage,
      totalLoss: prepared.totalLoss,
      excludeId: { id, logicalKey },
    });

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
    existing.rowNumber = prepared.rowNumber;

    await existing.save();

    return res.status(200).json({
      success: true,
      message: "Mud Loss - Storage updated successfully",
      data: existing,
    });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      success: false,
      message: error.statusCode
        ? error.message
        : "Failed to update Mud Loss - Storage",
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
