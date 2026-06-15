import WellGeneral from "../../modules/wellGeneral/wellGeneralModel.js";
import Casing from "../../modules/casing/casing.model.js";
import Pit from "../../modules/pit/pit.model.js";
import DrillString from "../../modules/DrillString/DrillString.js";
import ConsumeProduct from "../../modules/Consumeproduct/ConsumeProduct.js";
import ConsumeProductDistributionState from "../../modules/Consumeproduct/ConsumeProductDistributionState.js";
import ReceiveMud from "../../modules/receivemud/ReceiveMud.js";
import ReturnLostMud from "../../modules/returnlostmud/ReturnLostMud.js";
import AddWater from "../../modules/addwater/AddWater.js";
import OtherVolAddition from "../../modules/othervol/OtherVolAddition.js";
import MudLoss from "../../modules/mudloss/MudLoss.js";
import MudLossStorage from "../../modules/mudlossstorage/MudLossStorage.js";
import TransferMud from "../../modules/transfermud/TransferMud.js";
import EmptyFluidActiveSystem from "../../modules/emptyfluidactivesystem/EmptyFluidActiveSystem.js";
import Report from "../../modules/report/report.model.js";
import {
  operationInstancePayload,
  readOperationInstanceKey,
  withOperationInstanceScope,
} from "../../utils/operationInstanceScope.js";

const CONSUME_PRODUCT_LEGACY_OPERATION_INSTANCE_KEY = "consumeProduct::legacy0";

const getWellId = (req) => String(req.params.wellId || "").trim();
const getReportId = (req) =>
  String(req.query.reportId ?? req.body?.reportId ?? "").trim();
const getReportNo = (req) =>
  String(req.query.reportNo ?? req.body?.reportNo ?? "").trim();
const useStrictScope = (req) =>
  String(req.query.strictScope ?? req.body?.strictScope ?? "")
    .trim()
    .toLowerCase() === "true";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const toText = (value) => String(value ?? "").trim();

const round2 = (value) => {
  const n = Number(value);
  return Number.isFinite(n) ? Number(n.toFixed(2)) : 0;
};

const itemTime = (item = {}) =>
  new Date(item.updatedAt || item.createdAt || 0).getTime();

const rowSortOrder = (item = {}) => {
  const order = Number(item?.sortOrder);
  return Number.isFinite(order) ? order : null;
};

const latestRowsBySortOrder = (items = []) => {
  const latestByKey = new Map();
  const looseRows = [];

  for (const item of items) {
    const order = rowSortOrder(item);
    if (order === null) {
      looseRows.push(item);
      continue;
    }

    const key = String(order);
    const existing = latestByKey.get(key);
    if (!existing || itemTime(item) >= itemTime(existing)) {
      latestByKey.set(key, item);
    }
  }

  return [...latestByKey.values(), ...looseRows].sort((left, right) => {
    const leftOrder = rowSortOrder(left);
    const rightOrder = rowSortOrder(right);
    if (leftOrder !== null && rightOrder !== null && leftOrder !== rightOrder) {
      return leftOrder - rightOrder;
    }
    if (leftOrder !== null && rightOrder === null) return -1;
    if (leftOrder === null && rightOrder !== null) return 1;
    return itemTime(left) - itemTime(right);
  });
};

const mudLossStorageLogicalKey = (item = {}) => {
  const operationInstanceKey = toText(item.operationInstanceKey);
  const rowNumber = Number(item.rowNumber) || 0;
  if (operationInstanceKey && rowNumber > 0) {
    return `${operationInstanceKey}::row:${rowNumber}`;
  }

  const storage = toText(item.storage).toLowerCase();
  if (operationInstanceKey && storage) {
    return `${operationInstanceKey}::legacy:${storage}`;
  }

  return String(item._id || item.id || "");
};

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
    const operationInstanceKey = toText(item.operationInstanceKey);
    const rowNumber = Number(item.rowNumber) || 0;
    const storage = toText(item.storage).toLowerCase();
    if (operationInstanceKey && rowNumber > 0 && storage) {
      rowBasedStorageKeys.add(`${operationInstanceKey}::${storage}`);
    }
  }

  return Array.from(latestByKey.values()).filter((item) => {
    const operationInstanceKey = toText(item.operationInstanceKey);
    const rowNumber = Number(item.rowNumber) || 0;
    const storage = toText(item.storage).toLowerCase();
    if (!operationInstanceKey || rowNumber > 0 || !storage) return true;
    return !rowBasedStorageKeys.has(`${operationInstanceKey}::${storage}`);
  });
};

const normalizeAddWaterItems = (items = []) => {
  const latestTargetByInstance = new Map();

  for (const item of items) {
    const operationInstanceKey = toText(item.operationInstanceKey);
    if (!operationInstanceKey) continue;

    const current = latestTargetByInstance.get(operationInstanceKey);
    const currentTime = itemTime(item);
    if (!current || currentTime >= current.time) {
      latestTargetByInstance.set(operationInstanceKey, {
        target: toText(item.to).toLowerCase(),
        time: currentTime,
      });
    }
  }

  return items.filter((item) => {
    const operationInstanceKey = toText(item.operationInstanceKey);
    if (!operationInstanceKey) return true;

    const latest = latestTargetByInstance.get(operationInstanceKey);
    if (!latest) return true;
    return toText(item.to).toLowerCase() === latest.target;
  });
};

const normalizeOtherVolAdditionItems = (items = []) => {
  const latestByInstance = new Map();
  const unscopedItems = [];

  for (const item of items) {
    const operationInstanceKey = toText(item.operationInstanceKey);
    if (!operationInstanceKey) {
      unscopedItems.push(item);
      continue;
    }

    const existing = latestByInstance.get(operationInstanceKey);
    if (!existing || itemTime(item) >= itemTime(existing)) {
      latestByInstance.set(operationInstanceKey, item);
    }
  }

  return [...latestByInstance.values(), ...unscopedItems];
};

const rawCylinderVolume = ({ id, length }) => {
  const idIn = toNumber(id);
  const lengthFt = toNumber(length);
  if (idIn <= 0 || lengthFt <= 0) return 0;
  return (idIn * idIn * lengthFt) / 1029.4;
};

const calculatePipeVolume = ({ id, length }) => {
  return round2(rawCylinderVolume({ id, length }));
};

const normalizeHoleDiameterIn = (casing) => {
  const rawId = toNumber(casing?.id);
  if (rawId <= 0) return 0;

  const toc = toText(casing?.toc);
  if (toc === "__cased_hole__" && rawId > 0 && rawId < 2) {
    return rawId * 25.4;
  }

  if (rawId > 60) {
    return rawId / 25.4;
  }

  return rawId;
};

const casedHoleLength = (casing, mdInFeet) => {
  const md = toNumber(mdInFeet);
  const top = toNumber(casing?.top);
  const shoe = toNumber(casing?.shoe);

  if (top > 0 && shoe > 0 && top !== shoe) {
    return Math.abs(shoe - top);
  }

  if (shoe > 0 && top >= 0 && shoe !== top) {
    return Math.abs(shoe - top);
  }

  if (md > 0 && shoe > 0) {
    return Math.max(0, Math.min(md, shoe) - top);
  }

  if (md > 0) {
    return Math.max(0, md - top);
  }

  if (shoe > 0) {
    return Math.max(0, shoe - top);
  }

  return 0;
};

const validCasedHoleRows = (casings = [], mdInFeet) => {
  return latestRowsBySortOrder(casings).filter((row) => {
    return (
      normalizeHoleDiameterIn(row) > 0 &&
      casedHoleLength(row, mdInFeet) > 0
    );
  });
};

const casedHoleRowsForCalculation = (casings = [], mdInFeet) => {
  const validRows = validCasedHoleRows(casings, mdInFeet);

  if (validRows.length <= 1) {
    return validRows;
  }

  let selected = validRows[0];
  let selectedLength = casedHoleLength(selected, mdInFeet);

  for (const row of validRows.slice(1)) {
    const rowLength = casedHoleLength(row, mdInFeet);
    if (rowLength > selectedLength) {
      selected = row;
      selectedLength = rowLength;
    }
  }

  return selected ? [selected] : [];
};

const calculateCasedHoleRawVolume = (casings = [], mdInFeet) => {
  const validRows = validCasedHoleRows(casings, mdInFeet);
  const linerRows = validRows
    .map((row, index) => ({ row, index }))
    .filter(({ row }) => toNumber(row?.top) > 0);

  if (linerRows.length > 0) {
    const firstLiner = linerRows[0];
    const previousRow = validRows
      .slice(0, firstLiner.index)
      .reverse()
      .find((row) => normalizeHoleDiameterIn(row) > 0);

    const previousId = normalizeHoleDiameterIn(previousRow);
    const firstLinerTop = toNumber(firstLiner.row?.top);
    const previousVolume =
      previousId > 0 && firstLinerTop > 0
        ? rawCylinderVolume({ id: previousId, length: firstLinerTop })
        : 0;

    return linerRows.reduce((sum, { row }) => {
      const id = normalizeHoleDiameterIn(row);
      const length = casedHoleLength(row, mdInFeet);
      return sum + rawCylinderVolume({ id, length });
    }, previousVolume);
  }

  return casedHoleRowsForCalculation(casings, mdInFeet).reduce((sum, casing) => {
    const id = normalizeHoleDiameterIn(casing);
    const length = casedHoleLength(casing, mdInFeet);
    return sum + rawCylinderVolume({ id, length });
  }, 0);
};

const deepestCasedHoleShoe = (casings = [], mdInFeet) => {
  const validRows = validCasedHoleRows(casings, mdInFeet);
  const linerRows = validRows.filter((row) => toNumber(row?.top) > 0);

  if (linerRows.length > 0) {
    return linerRows.reduce((max, row) => {
      const shoe = toNumber(row?.shoe);
      return shoe > max ? shoe : max;
    }, 0);
  }

  return casedHoleRowsForCalculation(casings, mdInFeet).reduce((max, row) => {
    const shoe = toNumber(row?.shoe);
    return shoe > max ? shoe : max;
  }, 0);
};

const calculateOpenHoleRawVolume = (openHoleRows = [], startDepth = 0) => {
  let previousDepth = Math.max(0, toNumber(startDepth));

  return latestRowsBySortOrder(openHoleRows).reduce((sum, row) => {
    const id = toNumber(row?.id);
    const washout = toNumber(row?.washout);
    const md = toNumber(row?.md);
    const length = md > previousDepth ? md - previousDepth : 0;
    const effectiveId = id > 0 ? id * (1 + washout / 100) : 0;
    if (md > previousDepth) {
      previousDepth = md;
    }
    return sum + rawCylinderVolume({ id: effectiveId, length });
  }, 0);
};

const getDrillStringDepthLimit = (wellGeneral) => {
  const bitDepth = toNumber(wellGeneral?.bitDepth);
  if (bitDepth > 0) return bitDepth;

  const bitDepthIn = toNumber(wellGeneral?.bitDepthIn);
  if (bitDepthIn > 0) return bitDepthIn;

  const md = toNumber(wellGeneral?.md);
  if (md > 0) return md;

  return Infinity;
};

const calculateDrillStringGuideVolumes = (drillStrings = [], depthLimit) => {
  const rows = latestRowsBySortOrder(drillStrings);
  let remaining = depthLimit > 0 ? depthLimit : Infinity;
  let countedLength = 0;
  let pipeSteel = 0;
  let pipeInside = 0;

  for (const item of rows) {
    const length = toNumber(item?.length);
    if (length <= 0) continue;
    if (remaining <= 0) break;

    const piece = Number.isFinite(remaining) ? Math.min(length, remaining) : length;
    if (piece <= 0) continue;

    pipeSteel += rawCylinderVolume({ id: item?.od, length: piece });
    pipeInside += rawCylinderVolume({ id: item?.id, length: piece });
    countedLength += piece;

    if (Number.isFinite(remaining)) {
      remaining -= piece;
    }
  }

  return {
    pipeSteel,
    pipeInside,
    countedLength,
  };
};

const calculateCombinedHoleVolumeResult = ({
  casings = [],
  wellGeneral,
  drillStrings = [],
}) => {
  const md = toNumber(wellGeneral?.md);
  const openHoleRows = Array.isArray(wellGeneral?.openHoleRows)
    ? wellGeneral.openHoleRows
    : [];
  const casedHole = calculateCasedHoleRawVolume(casings, md);
  const openHoleStartDepth = deepestCasedHoleShoe(casings, md);
  const openHole = calculateOpenHoleRawVolume(openHoleRows, openHoleStartDepth);
  const drillString = calculateDrillStringGuideVolumes(
    drillStrings,
    getDrillStringDepthLimit(wellGeneral)
  );
  const holeSpace = casedHole + openHole;
  const pipeSteel = drillString.pipeSteel;
  const pipeInside = drillString.pipeInside;
  const hole = round2(holeSpace - pipeSteel + pipeInside);

  return {
    hole,
    casedHole: round2(casedHole),
    openHole: round2(openHole),
    holeSpace: round2(holeSpace),
    pipeSteel: round2(pipeSteel),
    pipeInside: round2(pipeInside),
    drillString: round2(pipeInside),
    drillStringCountedLength: round2(drillString.countedLength),
    hasData:
      Math.abs(holeSpace) >= 0.005 ||
      Math.abs(pipeSteel) >= 0.005 ||
      Math.abs(pipeInside) >= 0.005,
  };
};

const calculateCombinedHoleVolume = (args) =>
  calculateCombinedHoleVolumeResult(args).hole;

const legacyScopeFilter = (wellId) => ({
  wellId,
  $or: [{ reportId: { $exists: false } }, { reportId: null }, { reportId: "" }],
});

const legacyObjectIdScopeFilter = (wellId) => ({
  wellId,
  $or: [{ reportId: { $exists: false } }, { reportId: null }],
});

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

const resolveReportMeta = async ({ wellId, reportId, reportNo }) => {
  let report = null;

  if (reportId) {
    report = await Report.findOne({ _id: reportId, wellId }).lean().catch(() => null);
  }

  if (!report && reportNo) {
    report = await Report.findOne({ wellId, reportNo }).lean();
  }

  return {
    reportId: report ? toText(report._id) : reportId,
    reportNo: report ? toText(report.reportNo) : reportNo,
    userReportNo: report ? toText(report.userReportNo) : "",
    reportDate: report ? toText(report.reportDate) : "",
    carryOverCompletedAt: report?.carryOverCompletedAt ?? null,
    volumeNameHoleSnapshot:
      report?.volumeNameHoleSnapshot === null ||
      report?.volumeNameHoleSnapshot === undefined
        ? null
        : toNumber(report.volumeNameHoleSnapshot),
    volumeNameHoleDelta: report ? toNumber(report.volumeNameHoleDelta) : 0,
    volumeNameHoleActivePitsSnapshot:
      report?.volumeNameHoleActivePitsSnapshot === null ||
      report?.volumeNameHoleActivePitsSnapshot === undefined
        ? null
        : toNumber(report.volumeNameHoleActivePitsSnapshot),
    volumeNameLastActivePitVolume: report
      ? toNumber(report.volumeNameLastActivePitVolume)
      : 0,
  };
};

const filterRowsAfterCarryOverCutoff = (items = [], cutoff) => {
  const cutoffTime = new Date(cutoff || 0).getTime();
  if (!Number.isFinite(cutoffTime) || cutoffTime <= 0) return items;

  return items.filter((item) => {
    const createdTime = new Date(item?.createdAt || 0).getTime();
    return Number.isFinite(createdTime) && createdTime > cutoffTime;
  });
};

const rememberLastActivePitVolume = async ({ reportId, pitName, volume }) => {
  const cleanReportId = toText(reportId);
  if (!cleanReportId) return;

  await Report.updateOne(
    { _id: cleanReportId },
    {
      $set: {
        volumeNameLastActivePitName: toText(pitName),
        volumeNameLastActivePitVolume: round2(volume),
        volumeNameLastActivePitUpdatedAt: new Date(),
      },
    }
  );
};

const resolveSameReportHoleDelta = async ({
  reportMeta,
  hole,
  activePits,
  activePitsList = [],
}) => {
  const reportId = toText(reportMeta?.reportId);
  if (!reportId) return 0;

  const currentHole = round2(hole);
  const currentActivePits = round2(activePits);
  const previousHole = reportMeta?.volumeNameHoleSnapshot;

  if (
    Math.abs(currentHole) < 0.005 &&
    Math.abs(currentActivePits) < 0.005
  ) {
    await Report.updateOne(
      { _id: reportId },
      {
        $set: {
          volumeNameHoleSnapshot: 0,
          volumeNameHoleDelta: 0,
          volumeNameHoleActivePitsSnapshot: 0,
          volumeNameLastActivePitName: "",
          volumeNameLastActivePitVolume: 0,
          volumeNameLastActivePitUpdatedAt: null,
        },
      }
    );
    return 0;
  }

  if (previousHole === null || previousHole === undefined) {
    await Report.updateOne(
      { _id: reportId },
      {
        $set: {
          volumeNameHoleSnapshot: currentHole,
          volumeNameHoleDelta: 0,
          volumeNameHoleActivePitsSnapshot: currentActivePits,
        },
      }
    );
    return 0;
  }

  if (Math.abs(currentHole - toNumber(previousHole)) < 0.005) {
    const activePitsSnapshot = reportMeta?.volumeNameHoleActivePitsSnapshot;
    if (activePitsSnapshot === null || activePitsSnapshot === undefined) {
      await Report.updateOne(
        { _id: reportId },
        { $set: { volumeNameHoleActivePitsSnapshot: currentActivePits } }
      );
      return round2(reportMeta?.volumeNameHoleDelta);
    }

    const storedHoleDelta = round2(reportMeta?.volumeNameHoleDelta);
    const activePitsAdjustment = round2(
      currentActivePits - toNumber(activePitsSnapshot)
    );
    const lastActivePitVolume = round2(reportMeta?.volumeNameLastActivePitVolume);

    if (
      Math.abs(storedHoleDelta) < 0.005 &&
      Math.abs(activePitsAdjustment) > 0.005 &&
      Math.abs(lastActivePitVolume) > 0.005 &&
      Math.sign(lastActivePitVolume) === Math.sign(activePitsAdjustment)
    ) {
      return round2(-lastActivePitVolume);
    }

    const negativeActivePitVolume = round2(
      activePitsList.reduce((sum, pit) => {
        const volume = toNumber(pit?.volume);
        return volume < 0 ? sum + Math.abs(volume) : sum;
      }, 0)
    );
    if (activePitsAdjustment < -0.005 && negativeActivePitVolume > 0) {
      return negativeActivePitVolume;
    }

    const storedMagnitude = Math.abs(storedHoleDelta);
    const adjustmentMagnitude = Math.abs(activePitsAdjustment);
    const remainingMagnitude = storedMagnitude - adjustmentMagnitude;

    if (Math.abs(remainingMagnitude) < 0.005) return 0;

    if (remainingMagnitude < 0) {
      return round2(
        -Math.sign(activePitsAdjustment) * Math.abs(remainingMagnitude)
      );
    }

    return round2(Math.sign(storedHoleDelta) * remainingMagnitude);
  }

  const holeDelta = round2(toNumber(previousHole) - currentHole);
  await Report.updateOne(
    { _id: reportId },
    {
      $set: {
        volumeNameHoleSnapshot: currentHole,
        volumeNameHoleDelta: holeDelta,
        volumeNameHoleActivePitsSnapshot: currentActivePits,
      },
    }
  );
  return holeDelta;
};

const findScopedWellGeneral = async ({ wellId, reportId, reportNo }) => {
  if (reportId) {
    const byReportId = await WellGeneral.findOne({ wellId, reportId }).sort({
      updatedAt: -1,
      createdAt: -1,
    });
    if (byReportId) {
      return byReportId;
    }
  }

  if (reportNo) {
    const byReportNo = await WellGeneral.findOne({ wellId, reportNo }).sort({
      updatedAt: -1,
      createdAt: -1,
    });
    if (byReportNo) {
      return byReportNo;
    }
  }

  return null;
};

const findScopedCasings = async ({ wellId, reportId, strictScope = false }) => {
  if (reportId) {
    const scopedCasings = await Casing.find({ wellId, reportId }).sort({
      createdAt: 1,
      _id: 1,
    });

    if (scopedCasings.length > 0) {
      return scopedCasings;
    }

    if (strictScope) {
      return [];
    }

    return Casing.find(legacyScopeFilter(wellId)).sort({
      createdAt: 1,
      _id: 1,
    });
  }

  return Casing.find({ wellId }).sort({ createdAt: 1, _id: 1 });
};

const findScopedDrillStrings = async ({ wellId, reportId, strictScope = false }) => {
  if (reportId) {
    const scopedDrillStrings = await DrillString.find({ wellId, reportId })
      .sort({ createdAt: 1, _id: 1 })
      .limit(8)
      .lean();

    if (scopedDrillStrings.length > 0) {
      return scopedDrillStrings;
    }

    if (strictScope) {
      return [];
    }

    return DrillString.find(legacyObjectIdScopeFilter(wellId))
      .sort({ createdAt: 1, _id: 1 })
      .limit(8)
      .lean();
  }

  return DrillString.find({ wellId })
    .sort({ createdAt: 1, _id: 1 })
    .limit(8)
    .lean();
};

const findScopedPits = async ({ wellId, reportId }) => {
  if (reportId) {
    return Pit.find({ wellId, reportId }).sort({
      createdAt: 1,
      _id: 1,
    });
  }

  return Pit.find({ wellId }).sort({ createdAt: 1, _id: 1 });
};

const findPreviousReportMeta = async ({ wellId, reportMeta }) => {
  const currentReportId = toText(reportMeta?.reportId);
  const currentReportNo = Number.parseInt(toText(reportMeta?.reportNo), 10);
  let currentReport = null;

  if (currentReportId) {
    currentReport = await Report.findOne({ _id: currentReportId, wellId })
      .lean()
      .catch(() => null);
  }

  if (!currentReport && toText(reportMeta?.reportNo)) {
    currentReport = await Report.findOne({
      wellId,
      reportNo: toText(reportMeta.reportNo),
    }).lean();
  }

  if (Number.isFinite(currentReportNo) && currentReportNo > 1) {
    const previousReport = await Report.findOne({
      wellId,
      reportNo: String(currentReportNo - 1),
    }).lean();

    if (previousReport) {
      return {
        reportId: toText(previousReport._id),
        reportNo: toText(previousReport.reportNo),
      };
    }
  }

  const reports = await Report.find({ wellId }).lean();
  const currentId = toText(currentReport?._id || currentReportId);

  const numericPrevious = reports
    .filter((report) => {
      if (toText(report._id) === currentId) return false;
      const parsed = Number.parseInt(toText(report.reportNo), 10);
      return (
        Number.isFinite(currentReportNo) &&
        Number.isFinite(parsed) &&
        parsed < currentReportNo
      );
    })
    .sort((left, right) => {
      const leftNo = Number.parseInt(toText(left.reportNo), 10);
      const rightNo = Number.parseInt(toText(right.reportNo), 10);
      return rightNo - leftNo;
    })[0];

  if (numericPrevious) {
    return {
      reportId: toText(numericPrevious._id),
      reportNo: toText(numericPrevious.reportNo),
    };
  }

  const currentTime = new Date(
    currentReport?.reportDate || currentReport?.createdAt || currentReport?.updatedAt || 0
  ).getTime();

  if (Number.isFinite(currentTime) && currentTime > 0) {
    const chronologicalPrevious = reports
      .filter((report) => {
        if (toText(report._id) === currentId) return false;
        const reportTime = new Date(
          report.reportDate || report.createdAt || report.updatedAt || 0
        ).getTime();
        return Number.isFinite(reportTime) && reportTime < currentTime;
      })
      .sort((left, right) => {
        const leftTime = new Date(
          left.reportDate || left.createdAt || left.updatedAt || 0
        ).getTime();
        const rightTime = new Date(
          right.reportDate || right.createdAt || right.updatedAt || 0
        ).getTime();
        return rightTime - leftTime;
      })[0];

    if (chronologicalPrevious) {
      return {
        reportId: toText(chronologicalPrevious._id),
        reportNo: toText(chronologicalPrevious.reportNo),
      };
    }
  }

  return null;
};

const calculateHoleVolumeForReport = async ({ wellId, reportId, reportNo }) => {
  if (!reportId && !reportNo) return 0;

  const [wellGeneral, casings, drillStrings] = await Promise.all([
    findScopedWellGeneral({ wellId, reportId, reportNo }),
    findScopedCasings({ wellId, reportId }),
    findScopedDrillStrings({ wellId, reportId }),
  ]);

  return calculateCombinedHoleVolume({ casings, wellGeneral, drillStrings });
};

const calculateTotalOnLocationForReport = async ({ wellId, reportId, reportNo }) => {
  if (!reportId && !reportNo) return 0;

  const [wellGeneral, casings, drillStrings, pits] = await Promise.all([
    findScopedWellGeneral({ wellId, reportId, reportNo }),
    findScopedCasings({ wellId, reportId }),
    findScopedDrillStrings({ wellId, reportId }),
    findScopedPits({ wellId, reportId }),
  ]);

  const hole = calculateCombinedHoleVolume({ casings, wellGeneral, drillStrings });
  const previousReportMeta = await findPreviousReportMeta({
    wellId,
    reportMeta: { reportNo },
  });
  const previousHole = previousReportMeta
    ? await calculateHoleVolumeForReport({
        wellId,
        reportId: previousReportMeta.reportId,
        reportNo: previousReportMeta.reportNo,
      })
    : 0;
  const holeVolDifference = round2(hole - previousHole);
  const activePits = pits
    .filter((pit) => pit.initialActive === true)
    .reduce((sum, pit) => sum + toNumber(pit.volume), 0);
  const totalStorage = pits
    .filter((pit) => pit.initialActive === false)
    .reduce((sum, pit) => sum + toNumber(pit.volume), 0);

  return round2(activePits + holeVolDifference + totalStorage);
};

const findScopedConsumeProductDistributionStates = async ({
  wellId,
  reportId,
  strictScope = false,
  operationInstanceKey = "",
}) => {
  if (reportId) {
    const scopedFilter = withOperationInstanceScope(
      { wellId, reportId },
      operationInstanceKey,
      CONSUME_PRODUCT_LEGACY_OPERATION_INSTANCE_KEY
    );
    const scopedStates = await ConsumeProductDistributionState.find(
      scopedFilter
    ).sort({ updatedAt: -1, createdAt: -1 });

    if (scopedStates.length) {
      return scopedStates;
    }

    if (strictScope) {
      return [];
    }

    const legacyState = await ConsumeProductDistributionState.findOne(
      legacyScopeFilter(wellId)
    ).sort({
      updatedAt: -1,
      createdAt: -1,
    });
    return legacyState ? [legacyState] : [];
  }

  const latestState = await ConsumeProductDistributionState.findOne({ wellId }).sort({
    updatedAt: -1,
    createdAt: -1,
  });
  return latestState ? [latestState] : [];
};

const cleanDistributionRows = (items = []) =>
  items
    .map((item) => ({
      pitName: toText(item?.pitName),
      volume: Number(toNumber(item?.volume).toFixed(2)),
    }))
    .filter((item) => item.pitName && item.volume > 0);

const buildCalculatedVolumeMap = (distributionRows = [], activePitNames = new Set()) => {
  const calculatedVolumeByPit = new Map();
  const activeDeltaByPit = new Map();
  let activeSystemVolume = 0;
  const activeSystemRows = [];

  for (const row of distributionRows) {
    const key = toText(row.pitName).toLowerCase();
    if (!key) continue;

    if (key === "active system") {
      activeSystemVolume = Number((activeSystemVolume + toNumber(row.volume)).toFixed(2));
      activeSystemRows.push(row);
      continue;
    }

    if (activePitNames.has(key)) {
      addPitDelta(activeDeltaByPit, row.pitName, row.volume);
      continue;
    }

    const current = calculatedVolumeByPit.get(key) ?? 0;
    calculatedVolumeByPit.set(
      key,
      Number((current + toNumber(row.volume)).toFixed(2))
    );
  }

  return {
    activeSystemVolume,
    calculatedVolumeByPit,
    activeDeltaByPit,
    activeSystemRows,
  };
};

const isActiveSystemName = (value) =>
  toText(value).toLowerCase() === "active system";

const calculateAdjustedActiveSystemPendingInput = ({
  addWaterEntries = [],
  activeSystemDistributionRows = [],
  otherVolAdditions = [],
  activePitsList = [],
}) => {
  const activeSystemPendingEntries = [
    ...addWaterEntries.filter(
      (item) => isActiveSystemName(item?.to) && toNumber(item?.volume) > 0
    ),
    ...activeSystemDistributionRows.filter(
      (item) => toNumber(item?.volume) > 0
    ),
    ...otherVolAdditions.filter((item) => toNumber(item?.totalVolume) > 0),
  ];
  if (!activeSystemPendingEntries.length) return 0;

  const totalPending = round2(
    activeSystemPendingEntries.reduce(
      (sum, item) => sum + toNumber(item?.volume ?? item?.totalVolume),
      0
    )
  );
  const pendingTimes = activeSystemPendingEntries
    .map((item) => itemTime(item))
    .filter((time) => Number.isFinite(time) && time > 0);
  if (!pendingTimes.length) return 0;

  const firstPendingTime = Math.min(...pendingTimes);
  const adjustedActivePitVolume = activePitsList.reduce((sum, pit) => {
    const pitTime = itemTime(pit);
    if (!Number.isFinite(pitTime) || pitTime < firstPendingTime) return sum;
    return sum + toNumber(pit?.volume);
  }, 0);

  return round2(Math.min(totalPending, Math.max(0, adjustedActivePitVolume)));
};

const isIgnoredDestination = (value) => {
  const key = toText(value).toLowerCase();
  return !key || key === "imp";
};

const addPitDelta = (map, pitName, volume) => {
  const key = toText(pitName).toLowerCase();
  const amount = toNumber(volume);
  if (!key || Math.abs(amount) < 0.005) return;

  map.set(key, round2((map.get(key) ?? 0) + amount));
};

const addNamedPitDelta = ({
  pitName,
  volume,
  activePitNames,
  activeDeltaByPit,
  storageDeltaByPit,
}) => {
  const key = toText(pitName).toLowerCase();
  if (!key) return;

  addPitDelta(
    activePitNames.has(key) ? activeDeltaByPit : storageDeltaByPit,
    pitName,
    volume
  );
};

const buildOperationVolumeEffects = ({
  receivedMud = [],
  returnLostMud = [],
  addWaterEntries = [],
  otherVolAdditions = [],
  mudLossEntries = [],
  mudLossStorageEntries = [],
  transferMudEntries = [],
  emptyFluidEntries = [],
  activePitNames = new Set(),
}) => {
  let activeSystemDelta = 0;
  let addWaterActiveSystemDelta = 0;
  let otherVolActiveSystemDelta = 0;
  let endVolDelta = 0;
  let forceEndVolZero = false;
  const activeDeltaByPit = new Map();
  const storageDeltaByPit = new Map();

  for (const item of addWaterEntries) {
    const volume = toNumber(item.volume);
    if (isActiveSystemName(item.to)) {
      endVolDelta += volume;
      activeSystemDelta += volume;
      addWaterActiveSystemDelta += volume;
    } else if (activePitNames.has(toText(item.to).toLowerCase())) {
      activeSystemDelta += volume;
      addPitDelta(activeDeltaByPit, item.to, volume);
    } else {
      addPitDelta(storageDeltaByPit, item.to, volume);
    }
  }

  for (const item of receivedMud) {
    const volume = toNumber(item.netVolume);
    endVolDelta += volume;
      if (isActiveSystemName(item.to)) {
        activeSystemDelta += volume;
        addWaterActiveSystemDelta += volume;
      } else {
      addPitDelta(storageDeltaByPit, item.to, volume);
    }
  }

  for (const item of returnLostMud) {
    const returned = toNumber(item.volReturned);
    const lost = toNumber(item.volLost);
    endVolDelta -= returned + lost;
  }

  for (const item of otherVolAdditions) {
    const volume = toNumber(item.totalVolume);
    activeSystemDelta += volume;
    otherVolActiveSystemDelta += volume;
    endVolDelta += volume;
  }

  for (const item of mudLossEntries) {
    const volume = toNumber(item.totalLoss);
    activeSystemDelta -= volume;
    endVolDelta -= volume;
  }

  for (const item of mudLossStorageEntries) {
    addPitDelta(storageDeltaByPit, item.storage, -toNumber(item.totalLoss));
  }

  for (const item of transferMudEntries) {
    const transfers = Array.isArray(item.transfers) ? item.transfers : [];
    const rowTransferVol = transfers.reduce(
      (sum, row) => sum + toNumber(row?.volume),
      0
    );
    const totalTransferVol = transfers.length
      ? rowTransferVol
      : toNumber(item.totalTransferVol);

    if (isActiveSystemName(item.from)) {
      endVolDelta -= totalTransferVol;
      for (const row of transfers) {
        addNamedPitDelta({
          pitName: row?.pitName,
          volume: toNumber(row?.volume),
          activePitNames,
          activeDeltaByPit,
          storageDeltaByPit,
        });
      }
    } else {
      addNamedPitDelta({
        pitName: item.from,
        volume: -totalTransferVol,
        activePitNames,
        activeDeltaByPit,
        storageDeltaByPit,
      });
      for (const row of transfers) {
        const volume = toNumber(row?.volume);
        if (isActiveSystemName(row?.pitName)) {
          endVolDelta += volume;
        } else {
          addNamedPitDelta({
            pitName: row?.pitName,
            volume,
            activePitNames,
            activeDeltaByPit,
            storageDeltaByPit,
          });
        }
      }
    }
  }

  for (const item of emptyFluidEntries) {
    const volume = toNumber(item.volume || item.totalVolume);
    if (item.actionType === "Dump") {
      forceEndVolZero = true;
    } else if (item.actionType === "Transfer to Storage") {
      activeSystemDelta -= volume;
      endVolDelta -= volume;
      addPitDelta(storageDeltaByPit, item.pitName, volume);
    }
  }

  return {
    activeSystemDelta: round2(activeSystemDelta),
    addWaterActiveSystemDelta: round2(addWaterActiveSystemDelta),
    otherVolActiveSystemDelta: round2(otherVolActiveSystemDelta),
    endVolDelta: round2(endVolDelta),
    forceEndVolZero,
    activeDeltaByPit,
    storageDeltaByPit,
  };
};

const calculateEndVolForReport = async ({
  wellId,
  reportId,
  reportNo,
  visited = new Set(),
}) => {
  if (!reportId && !reportNo) return 0;

  const reportMeta = await resolveReportMeta({ wellId, reportId, reportNo });
  const reportKey = reportMeta.reportId || `reportNo:${reportMeta.reportNo}`;
  if (!reportKey || visited.has(reportKey)) return 0;

  const nextVisited = new Set(visited);
  nextVisited.add(reportKey);

  let [
    wellGeneral,
    casings,
    drillStrings,
    pits,
    distributionStates,
    receivedMud,
    returnLostMud,
    addWaterEntries,
    otherVolAdditions,
    mudLossEntries,
    mudLossStorageEntries,
    transferMudEntries,
    emptyFluidEntries,
  ] = await Promise.all([
    findScopedWellGeneral({
      wellId,
      reportId: reportMeta.reportId,
      reportNo: reportMeta.reportNo,
    }),
    findScopedCasings({ wellId, reportId: reportMeta.reportId, strictScope: true }),
    findScopedDrillStrings({
      wellId,
      reportId: reportMeta.reportId,
      strictScope: true,
    }),
    findScopedPits({ wellId, reportId: reportMeta.reportId }),
    findScopedConsumeProductDistributionStates({
      wellId,
      reportId: reportMeta.reportId,
      strictScope: true,
    }),
    ReceiveMud.find(scopedOperationFilter({ wellId, reportId: reportMeta.reportId }))
      .sort({ createdAt: 1, _id: 1 })
      .lean(),
    ReturnLostMud.find(
      scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
    )
      .sort({ createdAt: 1, _id: 1 })
      .lean(),
    AddWater.find(scopedOperationFilter({ wellId, reportId: reportMeta.reportId }))
      .sort({ createdAt: 1, _id: 1 })
      .lean(),
    OtherVolAddition.find(
      scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
    )
      .sort({ createdAt: 1, _id: 1 })
      .lean(),
    MudLoss.find(scopedOperationFilter({ wellId, reportId: reportMeta.reportId }))
      .sort({ createdAt: 1, _id: 1 })
      .lean(),
    MudLossStorage.find(
      scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
    )
      .sort({ createdAt: 1, _id: 1 })
      .lean(),
    TransferMud.find(
      scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
    )
      .sort({ createdAt: 1, _id: 1 })
      .lean(),
    EmptyFluidActiveSystem.find(
      scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
    )
      .sort({ createdAt: 1, _id: 1 })
      .lean(),
  ]);

  const carryOverCutoff = reportMeta.carryOverCompletedAt;
  distributionStates = filterRowsAfterCarryOverCutoff(
    distributionStates,
    carryOverCutoff
  );
  receivedMud = filterRowsAfterCarryOverCutoff(receivedMud, carryOverCutoff);
  returnLostMud = filterRowsAfterCarryOverCutoff(returnLostMud, carryOverCutoff);
  addWaterEntries = filterRowsAfterCarryOverCutoff(
    addWaterEntries,
    carryOverCutoff
  );
  otherVolAdditions = filterRowsAfterCarryOverCutoff(
    otherVolAdditions,
    carryOverCutoff
  );
  mudLossEntries = filterRowsAfterCarryOverCutoff(
    mudLossEntries,
    carryOverCutoff
  );
  mudLossStorageEntries = filterRowsAfterCarryOverCutoff(
    mudLossStorageEntries,
    carryOverCutoff
  );
  transferMudEntries = filterRowsAfterCarryOverCutoff(
    transferMudEntries,
    carryOverCutoff
  );
  emptyFluidEntries = filterRowsAfterCarryOverCutoff(
    emptyFluidEntries,
    carryOverCutoff
  );

  const hole = calculateCombinedHoleVolume({ casings, wellGeneral, drillStrings });
  const activePitsList = pits.filter((pit) => pit.initialActive === true);
  const activePitNames = new Set(
    activePitsList.map((pit) => toText(pit.pitName).toLowerCase()).filter(Boolean)
  );

  const distributionRows = (distributionStates ?? []).flatMap((state) =>
    cleanDistributionRows(state?.distributions ?? []).map((row) => ({
      ...row,
      updatedAt: state?.updatedAt,
      createdAt: state?.createdAt,
      operationInstanceKey: state?.operationInstanceKey,
    }))
  );
  const {
    activeSystemVolume,
    activeDeltaByPit: distributionActiveDeltaByPit,
    activeSystemRows: distributionActiveSystemRows,
  } = buildCalculatedVolumeMap(distributionRows, activePitNames);

  const normalizedMudLossStorageEntries =
    normalizeMudLossStorageItems(mudLossStorageEntries);
  const normalizedAddWaterEntries = normalizeAddWaterItems(addWaterEntries);
  const normalizedOtherVolAdditions =
    normalizeOtherVolAdditionItems(otherVolAdditions);

  const operationVolumeEffects = buildOperationVolumeEffects({
    receivedMud,
    returnLostMud,
    addWaterEntries: normalizedAddWaterEntries,
    otherVolAdditions: normalizedOtherVolAdditions,
    mudLossEntries,
    mudLossStorageEntries: normalizedMudLossStorageEntries,
    transferMudEntries,
    emptyFluidEntries,
    activePitNames,
  });

  const activePitsWithTransfer = activePitsList.reduce((sum, pit) => {
    const key = toText(pit.pitName).toLowerCase();
    const delta =
      (operationVolumeEffects.activeDeltaByPit.get(key) ?? 0) +
      (distributionActiveDeltaByPit.get(key) ?? 0);
    return sum + toNumber(pit.volume) + delta;
  }, 0);

  const derivedActiveSystem = round2(hole + activePitsWithTransfer);
  const activeSystemPendingInput = round2(
    operationVolumeEffects.addWaterActiveSystemDelta +
      activeSystemVolume +
      operationVolumeEffects.otherVolActiveSystemDelta
  );
  const adjustedActiveSystemPendingInput =
    calculateAdjustedActiveSystemPendingInput({
      addWaterEntries: normalizedAddWaterEntries,
      activeSystemDistributionRows: distributionActiveSystemRows,
      otherVolAdditions: normalizedOtherVolAdditions,
      activePitsList,
    });
  const pendingActiveSystemInput = round2(
    Math.max(0, activeSystemPendingInput - adjustedActiveSystemPendingInput)
  );
  const effectiveEndVolDelta = round2(
    operationVolumeEffects.endVolDelta -
      operationVolumeEffects.addWaterActiveSystemDelta +
      -operationVolumeEffects.otherVolActiveSystemDelta +
      pendingActiveSystemInput
  );
  const operationOnlyEndVolDelta = round2(
    operationVolumeEffects.endVolDelta -
      operationVolumeEffects.addWaterActiveSystemDelta +
      -operationVolumeEffects.otherVolActiveSystemDelta +
      activeSystemPendingInput
  );
  const hasOperationVolumeRows =
    distributionRows.length > 0 ||
    receivedMud.length > 0 ||
    returnLostMud.length > 0 ||
    normalizedAddWaterEntries.length > 0 ||
    normalizedOtherVolAdditions.length > 0 ||
    mudLossEntries.length > 0 ||
    normalizedMudLossStorageEntries.length > 0 ||
    transferMudEntries.length > 0 ||
    emptyFluidEntries.length > 0;

  const previousReportMeta = await findPreviousReportMeta({ wellId, reportMeta });
  const previousEndVol = previousReportMeta
    ? await calculateEndVolForReport({
        wellId,
        reportId: previousReportMeta.reportId,
        reportNo: previousReportMeta.reportNo,
        visited: nextVisited,
      })
    : 0;

  if (operationVolumeEffects.forceEndVolZero) return 0;

  if (!previousReportMeta && hasOperationVolumeRows) {
    return operationOnlyEndVolDelta;
  }

  if (derivedActiveSystem > 0 || Math.abs(effectiveEndVolDelta) >= 0.005) {
    return round2(previousEndVol + effectiveEndVolDelta);
  }

  return round2(previousEndVol);
};

const scopedOperationFilter = ({ wellId, reportId }) =>
  reportId ? { wellId, reportId } : legacyScopeFilter(wellId);

const buildWellGeneralPayload = ({ wellId, body, reportMeta, existing }) => ({
  wellId,
  reportId: reportMeta.reportId || toText(existing?.reportId),
  reportNo:
    toText(body.reportNo) || reportMeta.reportNo || toText(existing?.reportNo),
  userReportNo:
    toText(body.userReportNo) ||
    reportMeta.userReportNo ||
    toText(existing?.userReportNo),
  date: toText(body.date) || reportMeta.reportDate || toText(existing?.date),
  time: toText(body.time) || toText(existing?.time),
  engineer: toText(body.engineer) || toText(existing?.engineer),
  engineer2: toText(body.engineer2) || toText(existing?.engineer2),
  operatorRep: toText(body.operatorRep) || toText(existing?.operatorRep),
  contractorRep: toText(body.contractorRep) || toText(existing?.contractorRep),
  activity: toText(body.activity) || toText(existing?.activity),
  md: toNumber(body.md ?? existing?.md),
  tvd: toNumber(body.tvd ?? existing?.tvd),
  inc: toNumber(body.inc ?? existing?.inc),
  azi: toNumber(body.azi ?? existing?.azi),
  wob: toNumber(body.wob ?? existing?.wob),
  rotWt: toNumber(body.rotWt ?? existing?.rotWt),
  soWt: toNumber(body.soWt ?? existing?.soWt),
  puWt: toNumber(body.puWt ?? existing?.puWt),
  rpm: toNumber(body.rpm ?? existing?.rpm),
  rop: toNumber(body.rop ?? existing?.rop),
  offBottomTq: toNumber(body.offBottomTq ?? existing?.offBottomTq),
  onBottomTq: toNumber(body.onBottomTq ?? existing?.onBottomTq),
  suctionT: toNumber(body.suctionT ?? existing?.suctionT),
  bottomT: toNumber(body.bottomT ?? existing?.bottomT),
  interval: toText(body.interval) || toText(existing?.interval),
  fit: toText(body.fit) || toText(existing?.fit),
  formation: toText(body.formation) || toText(existing?.formation),
  additionalFootage: toNumber(
    body.additionalFootage ?? existing?.additionalFootage
  ),
  nptTime: toNumber(body.nptTime ?? existing?.nptTime),
  nptCost: toNumber(body.nptCost ?? existing?.nptCost),
  depthDrilled: toNumber(body.depthDrilled ?? existing?.depthDrilled),
});

// ------------------ SAVE WELL GENERAL ------------------
export const createWellGeneral = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const requestReportId = getReportId(req);
    const requestReportNo = getReportNo(req);
    const recordId = toText(req.body.recordId);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const reportMeta = await resolveReportMeta({
      wellId,
      reportId: requestReportId,
      reportNo: requestReportNo,
    });

    let item = await findScopedWellGeneral({
      wellId,
      reportId: reportMeta.reportId,
      reportNo: reportMeta.reportNo,
    });

    if (!item && recordId) {
      item = await WellGeneral.findOne({ _id: recordId, wellId });
    }

    const payload = buildWellGeneralPayload({
      wellId,
      body: req.body,
      reportMeta,
      existing: item,
    });

    if (item) {
      Object.assign(item, payload);
      await item.save();

      return res.status(200).json({
        success: true,
        message: "Well general updated successfully",
        data: item,
      });
    }

    item = await WellGeneral.create(payload);

    return res.status(201).json({
      success: true,
      message: "Well general saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ------------------ SAVE CASING ------------------
export const createCasing = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = getReportId(req);

    const {
      description,
      type,
      od,
      wt,
      id,
      top,
      shoe,
      bit,
      toc,
    } = req.body;

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const item = await Casing.create({
      wellId,
      reportId,
      description: description || "",
      type: type || "",
      od: od || "",
      wt: wt || "",
      id: id || "",
      top: top || "",
      shoe: shoe || "",
      bit: bit || "",
      toc: toc || "",
    });

    return res.status(201).json({
      success: true,
      message: "Casing saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ------------------ SAVE CONSUME PRODUCT ------------------
export const createConsumeProduct = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = getReportId(req);
    const operationInstanceKey = operationInstancePayload(req);
    const inputMethod = toText(req.body.inputMethod) || "Used";
    const addWaterEnabled = Boolean(req.body.addWater);
    const addWaterVolume = Number(toNumber(req.body.addWaterVolume).toFixed(2));
    const totalVolume = Number(toNumber(req.body.totalVolume).toFixed(2));
    const distributions = cleanDistributionRows(req.body.distributions);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const hasMeaningfulState = totalVolume > 0 || distributions.length > 0 || addWaterEnabled;

    if (!hasMeaningfulState) {
      await ConsumeProductDistributionState.deleteMany(
        withOperationInstanceScope(
          scopedOperationFilter({ wellId, reportId }),
          operationInstanceKey,
          CONSUME_PRODUCT_LEGACY_OPERATION_INSTANCE_KEY
        )
      );

      return res.status(200).json({
        success: true,
        message: "Consume product distribution cleared successfully",
        data: {
          wellId,
          reportId,
          operationInstanceKey,
          inputMethod,
          addWaterEnabled: false,
          addWaterVolume: 0,
          totalVolume: 0,
          distributions: [],
        },
      });
    }

    const item = await ConsumeProductDistributionState.findOneAndUpdate(
      withOperationInstanceScope(
        scopedOperationFilter({ wellId, reportId }),
        operationInstanceKey,
        CONSUME_PRODUCT_LEGACY_OPERATION_INSTANCE_KEY
      ),
      {
        wellId,
        reportId,
        operationInstanceKey,
        inputMethod,
        addWaterEnabled,
        addWaterVolume,
        totalVolume,
        distributions,
      },
      {
        new: true,
        upsert: true,
        setDefaultsOnInsert: true,
      }
    );

    return res.status(200).json({
      success: true,
      message: "Consume product distribution saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ------------------ SAVE / UPDATE PIT VOLUME DATA ------------------
export const createPit = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = getReportId(req);
    const pitName = toText(req.body.pitName);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    if (!pitName) {
      return res.status(400).json({
        success: false,
        message: "pitName is required",
      });
    }

    const pitPayload = {
      wellId,
      pitName,
      volume: Number(req.body.volume) || 0,
      density: Number(req.body.density) || 0,
      fluidType: toText(req.body.fluidType),
      capacity: Number(req.body.capacity) || 0,
      initialActive: Boolean(req.body.initialActive),
      reportId,
    };

    let item = null;

    if (reportId) {
      item = await Pit.findOne({
        wellId,
        reportId,
        pitName,
      }).sort({ createdAt: -1, _id: -1 });
    }

    if (!item && !reportId) {
      item = await Pit.findOne({
        wellId,
        pitName,
      }).sort({ createdAt: -1, _id: -1 });
    }

    if (item) {
      item.volume = pitPayload.volume;
      item.density = pitPayload.density;
      item.fluidType = pitPayload.fluidType;
      item.capacity = pitPayload.capacity;
      item.initialActive = pitPayload.initialActive;
      item.reportId = pitPayload.reportId;
      await item.save();
      if (reportId && pitPayload.initialActive) {
        await rememberLastActivePitVolume({
          reportId,
          pitName,
          volume: pitPayload.volume,
        });
      }

      return res.status(200).json({
        success: true,
        message: "Pit updated successfully",
        data: item,
      });
    }

    item = await Pit.create(pitPayload);
    if (reportId && pitPayload.initialActive) {
      await rememberLastActivePitVolume({
        reportId,
        pitName,
        volume: pitPayload.volume,
      });
    }

    return res.status(201).json({
      success: true,
      message: "Pit saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ------------------ GET VOLUME NAME ------------------
export const getVolumeNameCalculation = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = getReportId(req);
    const reportNo = getReportNo(req);
    const strictScope = useStrictScope(req);
    const operationInstanceKey = readOperationInstanceKey(req);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const reportMeta = await resolveReportMeta({ wellId, reportId, reportNo });

    let [wellGeneral, casings, drillStrings, pits, distributionStates, consumeProducts, receivedMud, returnLostMud, addWaterEntries, otherVolAdditions, mudLossEntries, mudLossStorageEntries, transferMudEntries, emptyFluidEntries] =
      await Promise.all([
        findScopedWellGeneral({
          wellId,
          reportId: reportMeta.reportId,
          reportNo: reportMeta.reportNo,
        }),
        findScopedCasings({
          wellId,
          reportId: reportMeta.reportId,
          strictScope,
        }),
        findScopedDrillStrings({
          wellId,
          reportId: reportMeta.reportId,
          strictScope,
        }),
        findScopedPits({ wellId, reportId: reportMeta.reportId }),
        findScopedConsumeProductDistributionStates({
          wellId,
          reportId: reportMeta.reportId,
          strictScope,
          operationInstanceKey,
        }),
        ConsumeProduct.find(
          scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
        ).sort({ createdAt: 1, _id: 1 }),
        ReceiveMud.find(
          scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
        ).sort({ createdAt: 1, _id: 1 }),
        ReturnLostMud.find(
          scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
        ).sort({ createdAt: 1, _id: 1 }),
        AddWater.find(
          scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
        ).sort({ createdAt: 1, _id: 1 }),
        OtherVolAddition.find(
          scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
        ).sort({ createdAt: 1, _id: 1 }),
        MudLoss.find(
          scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
        ).sort({ createdAt: 1, _id: 1 }),
        MudLossStorage.find(
          scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
        ).sort({ createdAt: 1, _id: 1 }),
        TransferMud.find(
          scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
        ).sort({ createdAt: 1, _id: 1 }),
        EmptyFluidActiveSystem.find(
          scopedOperationFilter({ wellId, reportId: reportMeta.reportId })
        ).sort({ createdAt: 1, _id: 1 }),
      ]);

    const carryOverCutoff = reportMeta.carryOverCompletedAt;
    distributionStates = filterRowsAfterCarryOverCutoff(
      distributionStates,
      carryOverCutoff
    );
    consumeProducts = filterRowsAfterCarryOverCutoff(
      consumeProducts,
      carryOverCutoff
    );
    receivedMud = filterRowsAfterCarryOverCutoff(receivedMud, carryOverCutoff);
    returnLostMud = filterRowsAfterCarryOverCutoff(
      returnLostMud,
      carryOverCutoff
    );
    addWaterEntries = filterRowsAfterCarryOverCutoff(
      addWaterEntries,
      carryOverCutoff
    );
    otherVolAdditions = filterRowsAfterCarryOverCutoff(
      otherVolAdditions,
      carryOverCutoff
    );
    mudLossEntries = filterRowsAfterCarryOverCutoff(
      mudLossEntries,
      carryOverCutoff
    );
    mudLossStorageEntries = filterRowsAfterCarryOverCutoff(
      mudLossStorageEntries,
      carryOverCutoff
    );
    transferMudEntries = filterRowsAfterCarryOverCutoff(
      transferMudEntries,
      carryOverCutoff
    );
    emptyFluidEntries = filterRowsAfterCarryOverCutoff(
      emptyFluidEntries,
      carryOverCutoff
    );

    const normalizedMudLossStorageEntries =
      normalizeMudLossStorageItems(mudLossStorageEntries);
    const normalizedAddWaterEntries = normalizeAddWaterItems(addWaterEntries);
    const normalizedOtherVolAdditions =
      normalizeOtherVolAdditionItems(otherVolAdditions);

    const md = toNumber(wellGeneral?.md);

    const validCasings = casings.filter((row) => toNumber(row.id) > 0);
    const latestCasing = validCasings.length
      ? validCasings[validCasings.length - 1]
      : null;

    const casingId = toNumber(latestCasing?.id);
    const holeVolumeResult = calculateCombinedHoleVolumeResult({
      casings,
      wellGeneral,
      drillStrings,
    });
    const hole = holeVolumeResult.hole;
    const previousReportMeta = await findPreviousReportMeta({
      wellId,
      reportMeta,
    });
    const previousHole = previousReportMeta
      ? await calculateHoleVolumeForReport({
          wellId,
          reportId: previousReportMeta.reportId,
          reportNo: previousReportMeta.reportNo,
        })
      : 0;
    const previousEndVol = previousReportMeta
      ? await calculateEndVolForReport({
          wellId,
          reportId: previousReportMeta.reportId,
          reportNo: previousReportMeta.reportNo,
        })
      : 0;
    const heldVolDifference = holeVolumeResult.hasData
      ? round2(hole - previousHole)
      : 0;
    const drillstringVolume = holeVolumeResult.pipeInside;
    const annulus = Number(Math.max(0, hole - drillstringVolume).toFixed(2));
    const belowBit = 0;
    const displacement = 0;

    const activePitsList = pits.filter((pit) => pit.initialActive === true);
    const storagePitsList = pits.filter((pit) => pit.initialActive === false);
    const activePitNames = new Set(
      activePitsList.map((pit) => toText(pit.pitName).toLowerCase()).filter(Boolean)
    );

    const activePits = Number(
      activePitsList.reduce((sum, pit) => sum + toNumber(pit.volume), 0).toFixed(2)
    );
    const sameReportHoleDelta = await resolveSameReportHoleDelta({
      reportMeta,
      hole,
      activePits,
      activePitsList,
    });

    const totalStorage = Number(
      storagePitsList.reduce((sum, pit) => sum + toNumber(pit.volume), 0).toFixed(2)
    );

    const distributionRows = (distributionStates ?? []).flatMap((state) =>
      cleanDistributionRows(state?.distributions ?? []).map((row) => ({
        ...row,
        updatedAt: state?.updatedAt,
        createdAt: state?.createdAt,
        operationInstanceKey: state?.operationInstanceKey,
      }))
    );
    const primaryDistributionState = (distributionStates ?? [])[0];
    const {
      activeSystemVolume,
      calculatedVolumeByPit,
      activeDeltaByPit: distributionActiveDeltaByPit,
      activeSystemRows: distributionActiveSystemRows,
    } = buildCalculatedVolumeMap(distributionRows, activePitNames);
    for (const pit of storagePitsList) {
      const key = toText(pit.pitName).toLowerCase();
      if (!key || calculatedVolumeByPit.has(key)) continue;
      calculatedVolumeByPit.set(key, toNumber(pit.volume));
    }
    const operationVolumeEffects = buildOperationVolumeEffects({
      receivedMud,
      returnLostMud,
      addWaterEntries: normalizedAddWaterEntries,
      otherVolAdditions: normalizedOtherVolAdditions,
      mudLossEntries,
      mudLossStorageEntries: normalizedMudLossStorageEntries,
      transferMudEntries,
      emptyFluidEntries,
      activePitNames,
    });
    const activePitsWithTransfer = activePitsList.reduce((sum, pit) => {
      const key = toText(pit.pitName).toLowerCase();
      const delta =
        (operationVolumeEffects.activeDeltaByPit.get(key) ?? 0) +
        (distributionActiveDeltaByPit.get(key) ?? 0);
      return sum + toNumber(pit.volume) + delta;
    }, 0);
    for (const [pitName, volume] of operationVolumeEffects.storageDeltaByPit) {
      addPitDelta(calculatedVolumeByPit, pitName, volume);
    }
    const derivedActiveSystem = round2(hole + activePitsWithTransfer);
    const activeSystem = derivedActiveSystem;
    const activeSystemPendingInput = round2(
      operationVolumeEffects.addWaterActiveSystemDelta +
        activeSystemVolume +
        operationVolumeEffects.otherVolActiveSystemDelta
    );
    const adjustedActiveSystemPendingInput =
      calculateAdjustedActiveSystemPendingInput({
        addWaterEntries: normalizedAddWaterEntries,
        activeSystemDistributionRows: distributionActiveSystemRows,
        otherVolAdditions: normalizedOtherVolAdditions,
        activePitsList,
      });
    const pendingActiveSystemInput = round2(
      Math.max(
        0,
        activeSystemPendingInput - adjustedActiveSystemPendingInput
      )
    );
    const effectiveEndVolDelta = round2(
      operationVolumeEffects.endVolDelta -
        operationVolumeEffects.addWaterActiveSystemDelta +
        -operationVolumeEffects.otherVolActiveSystemDelta +
        pendingActiveSystemInput
    );
    const operationOnlyEndVolDelta = round2(
      operationVolumeEffects.endVolDelta -
        operationVolumeEffects.addWaterActiveSystemDelta +
        -operationVolumeEffects.otherVolActiveSystemDelta +
        activeSystemPendingInput
    );
    const hasOperationVolumeRows =
      distributionRows.length > 0 ||
      receivedMud.length > 0 ||
      returnLostMud.length > 0 ||
      normalizedAddWaterEntries.length > 0 ||
      normalizedOtherVolAdditions.length > 0 ||
      mudLossEntries.length > 0 ||
      normalizedMudLossStorageEntries.length > 0 ||
      transferMudEntries.length > 0 ||
      emptyFluidEntries.length > 0;
    const firstReportStartsEmpty =
      !previousReportMeta &&
      !hasOperationVolumeRows &&
      Math.abs(effectiveEndVolDelta) < 0.005 &&
      !operationVolumeEffects.forceEndVolZero;
    const reportIdForSnapshot = toText(reportMeta?.reportId);
    if (
      firstReportStartsEmpty &&
      reportIdForSnapshot &&
      (Math.abs(sameReportHoleDelta) > 0.005 ||
        Math.abs(toNumber(reportMeta?.volumeNameHoleSnapshot) - hole) > 0.005 ||
        Math.abs(toNumber(reportMeta?.volumeNameHoleDelta)) > 0.005 ||
        Math.abs(toNumber(reportMeta?.volumeNameHoleActivePitsSnapshot) - activePits) >
          0.005)
    ) {
      await Report.updateOne(
        { _id: reportIdForSnapshot },
        {
          $set: {
            volumeNameHoleSnapshot: round2(hole),
            volumeNameHoleDelta: 0,
            volumeNameHoleActivePitsSnapshot: activePits,
            volumeNameLastActivePitName: "",
            volumeNameLastActivePitVolume: 0,
            volumeNameLastActivePitUpdatedAt: null,
          },
        }
      );
    }
    const operationEndVol = operationVolumeEffects.forceEndVolZero
      ? 0
      : round2(derivedActiveSystem + effectiveEndVolDelta);
    const firstReportOperationEndVol =
      !previousReportMeta && hasOperationVolumeRows
        ? operationOnlyEndVolDelta
        : null;
    const endVolBase = round2(previousEndVol);
    const endVol = operationVolumeEffects.forceEndVolZero
      ? 0
      : firstReportStartsEmpty
        ? 0
      : firstReportOperationEndVol !== null
        ? firstReportOperationEndVol
      : endVolBase > 0
        ? round2(endVolBase + effectiveEndVolDelta)
        : Math.abs(effectiveEndVolDelta) >= 0.005
          ? operationEndVol
          : 0;
    const baseEndVolMinusActiveSystem = round2(endVol - activeSystem);
    let endVolMinusActiveSystem = 0;
    if (firstReportStartsEmpty || hasOperationVolumeRows) {
      endVolMinusActiveSystem = baseEndVolMinusActiveSystem;
    } else if (Math.abs(baseEndVolMinusActiveSystem) < 0.005) {
      endVolMinusActiveSystem = sameReportHoleDelta;
    } else if (Math.abs(sameReportHoleDelta) < 0.005) {
      endVolMinusActiveSystem = baseEndVolMinusActiveSystem;
    } else if (
      Math.sign(baseEndVolMinusActiveSystem) === Math.sign(sameReportHoleDelta)
    ) {
      endVolMinusActiveSystem = baseEndVolMinusActiveSystem;
    } else {
      endVolMinusActiveSystem = round2(
        baseEndVolMinusActiveSystem + sameReportHoleDelta
      );
    }

    const consumeProductTotal = Number(
      consumeProducts.reduce((sum, item) => sum + toNumber(item.volumeBbl), 0).toFixed(2)
    );

    const receivedMudTotal = Number(
      receivedMud.reduce((sum, item) => sum + toNumber(item.netVolume), 0).toFixed(2)
    );

    const lostMudTotal = Number(
      returnLostMud.reduce((sum, item) => sum + toNumber(item.volLost), 0).toFixed(2)
    );

    const addWaterTotal = Number(
      normalizedAddWaterEntries
        .reduce((sum, item) => sum + toNumber(item.volume), 0)
        .toFixed(2)
    );

    const mudLossTotal = Number(
      mudLossEntries.reduce((sum, item) => sum + toNumber(item.totalLoss), 0).toFixed(2)
    );

    const mudLossStorageTotal = Number(
      normalizedMudLossStorageEntries
        .reduce((sum, item) => sum + toNumber(item.totalLoss), 0)
        .toFixed(2)
    );

    const otherVolAdditionTotal = Number(
      normalizedOtherVolAdditions
        .reduce((sum, item) => sum + toNumber(item.totalVolume), 0)
        .toFixed(2)
    );

    const ledgerTotalOnLocation = Number(
      (
        consumeProductTotal +
        receivedMudTotal +
        addWaterTotal +
        otherVolAdditionTotal -
        lostMudTotal -
        mudLossTotal -
        mudLossStorageTotal
      ).toFixed(2)
    );
    const totalOnLocation = Number((activeSystem + totalStorage).toFixed(2));
    const previousTotalOnLocation = previousReportMeta
      ? await calculateTotalOnLocationForReport({
          wellId,
          reportId: previousReportMeta.reportId,
          reportNo: previousReportMeta.reportNo,
        })
      : 0;

    return res.status(200).json({
      success: true,
      message: "Volume Name calculation fetched successfully",
      data: {
        wellId,
        reportId: reportMeta.reportId,
        reportNo: reportMeta.reportNo,
        general: {
          md,
        },
        casing: {
          id: casingId,
          top: toNumber(latestCasing?.top),
          shoe: toNumber(latestCasing?.shoe),
          description: latestCasing?.description || "",
        },
        holeVolumeBreakdown: {
          casedHole: holeVolumeResult.casedHole,
          openHole: holeVolumeResult.openHole,
          drillStringHole: holeVolumeResult.drillString,
          holeSpace: holeVolumeResult.holeSpace,
          pipeSteel: holeVolumeResult.pipeSteel,
          pipeInside: holeVolumeResult.pipeInside,
          drillStringCountedLength: holeVolumeResult.drillStringCountedLength,
          string: drillstringVolume,
          annulus,
          belowBit,
          hole,
          displacement,
        },
        volumeName: {
          heldVolDifference,
          hole,
          activePits: round2(activePitsWithTransfer),
          activeSystem,
          endVol,
          endVolMinusActiveSystem,
          totalStorage,
          totalOnLocation,
          ledgerTotalOnLocation,
          previousTotalOnLocation,
        },
        totalsBreakdown: {
          consumeProductTotal,
          receivedMudTotal,
          addWaterTotal,
          otherVolAdditionTotal,
          lostMudTotal,
          mudLossTotal,
          mudLossStorageTotal,
          transferMudTotal: Number(
            transferMudEntries
              .reduce((sum, item) => sum + toNumber(item.totalTransferVol), 0)
              .toFixed(2)
          ),
          emptyFluidTotal: Number(
            emptyFluidEntries
              .reduce((sum, item) => sum + toNumber(item.volume || item.totalVolume), 0)
              .toFixed(2)
          ),
          operationActiveSystemDelta: operationVolumeEffects.activeSystemDelta,
          operationEndVolDelta: effectiveEndVolDelta,
          operationEndVol,
          pendingActiveSystemWater: pendingActiveSystemInput,
        },
        consumeProductDistribution: {
          inputMethod: toText(primaryDistributionState?.inputMethod) || "Used",
          addWaterEnabled: Boolean(primaryDistributionState?.addWaterEnabled),
          addWaterVolume: Number(
            toNumber(primaryDistributionState?.addWaterVolume).toFixed(2)
          ),
          totalVolume: Number(
            toNumber(primaryDistributionState?.totalVolume).toFixed(2)
          ),
          activeSystemVolume,
          distributions: distributionRows,
        },
        activePitsTable: activePitsList.map((pit) => {
          const key = toText(pit.pitName).toLowerCase();
          const delta =
            (operationVolumeEffects.activeDeltaByPit.get(key) ?? 0) +
            (distributionActiveDeltaByPit.get(key) ?? 0);
          return {
            _id: pit._id,
            pitName: pit.pitName,
            capacity: toNumber(pit.capacity),
            measuredVol: round2(toNumber(pit.volume) + delta),
            mw: toNumber(pit.density),
            mud: pit.fluidType || "",
            reportId: pit.reportId || "",
          };
        }),
        storageTable: storagePitsList.map((pit) => ({
          _id: pit._id,
          pitName: pit.pitName,
          capacity: toNumber(pit.capacity),
          calculatedVol: calculatedVolumeByPit.get(toText(pit.pitName).toLowerCase()) ?? 0,
          measuredVol: toNumber(pit.volume),
          mw: toNumber(pit.density),
          fluidType: pit.fluidType || "",
          reportId: pit.reportId || "",
        })),
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to calculate volume name data",
      error: error.message,
    });
  }
};
