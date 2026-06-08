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

const calculatePipeVolume = ({ id, length }) => {
  const idIn = toNumber(id);
  const lengthFt = toNumber(length);
  if (idIn <= 0 || lengthFt <= 0) return 0;
  return round2((idIn * idIn * lengthFt) / 1029.4);
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

const calculateHoleVolume = (casing, mdInFeet) => {
  const id = normalizeHoleDiameterIn(casing);
  const md = toNumber(mdInFeet);
  const top = toNumber(casing?.top);
  const shoe = toNumber(casing?.shoe);

  if (id <= 0) return 0;

  let length = 0;

  if (md > 0 && shoe > 0) {
    length = Math.max(0, Math.min(md, shoe) - top);
  } else if (md > 0) {
    length = Math.max(0, md - top);
  } else if (shoe > 0) {
    length = Math.max(0, shoe - top);
  }

  if (length <= 0) {
    length = md > 0 ? md : shoe;
  }

  if (length <= 0) return 0;

  return round2((id * id * length) / 1029.4);
};

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
  };
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

const findScopedCasings = async ({ wellId, reportId }) => {
  if (reportId) {
    const scopedCasings = await Casing.find({ wellId, reportId }).sort({
      createdAt: 1,
      _id: 1,
    });

    if (scopedCasings.length > 0) {
      return scopedCasings;
    }

    return Casing.find(legacyScopeFilter(wellId)).sort({
      createdAt: 1,
      _id: 1,
    });
  }

  return Casing.find({ wellId }).sort({ createdAt: 1, _id: 1 });
};

const findScopedDrillStrings = async ({ wellId, reportId }) => {
  if (reportId) {
    const scopedDrillStrings = await DrillString.find({ wellId, reportId })
      .sort({ createdAt: 1, _id: 1 })
      .limit(8)
      .lean();

    if (scopedDrillStrings.length > 0) {
      return scopedDrillStrings;
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
  const currentReportNo = Number.parseInt(toText(reportMeta?.reportNo), 10);

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

  return null;
};

const calculateHoleVolumeForReport = async ({ wellId, reportId, reportNo }) => {
  if (!reportId && !reportNo) return 0;

  const [wellGeneral, casings] = await Promise.all([
    findScopedWellGeneral({ wellId, reportId, reportNo }),
    findScopedCasings({ wellId, reportId }),
  ]);

  const md = toNumber(wellGeneral?.md);
  const validCasings = casings.filter((row) => toNumber(row.id) > 0);
  const latestCasing = validCasings.length
    ? validCasings[validCasings.length - 1]
    : null;

  return calculateHoleVolume(latestCasing, md);
};

const calculateTotalOnLocationForReport = async ({ wellId, reportId, reportNo }) => {
  if (!reportId && !reportNo) return 0;

  const [wellGeneral, casings, pits] = await Promise.all([
    findScopedWellGeneral({ wellId, reportId, reportNo }),
    findScopedCasings({ wellId, reportId }),
    findScopedPits({ wellId, reportId }),
  ]);

  const md = toNumber(wellGeneral?.md);
  const validCasings = casings.filter((row) => toNumber(row.id) > 0);
  const latestCasing = validCasings.length
    ? validCasings[validCasings.length - 1]
    : null;

  const hole = calculateHoleVolume(latestCasing, md);
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

const calculateAdjustedActiveSystemWater = ({
  addWaterEntries = [],
  activeSystemDistributionRows = [],
  activePitsList = [],
}) => {
  const activeSystemWaterEntries = [
    ...addWaterEntries.filter(
      (item) => isActiveSystemName(item?.to) && toNumber(item?.volume) > 0
    ),
    ...activeSystemDistributionRows.filter(
      (item) => toNumber(item?.volume) > 0
    ),
  ];
  if (!activeSystemWaterEntries.length) return 0;

  const totalWater = round2(
    activeSystemWaterEntries.reduce(
      (sum, item) => sum + toNumber(item?.volume),
      0
    )
  );
  const waterTimes = activeSystemWaterEntries
    .map((item) => itemTime(item))
    .filter((time) => Number.isFinite(time) && time > 0);
  if (!waterTimes.length) return 0;

  const firstWaterTime = Math.min(...waterTimes);
  const adjustedActivePitVolume = activePitsList.reduce((sum, pit) => {
    const pitTime = itemTime(pit);
    if (!Number.isFinite(pitTime) || pitTime < firstWaterTime) return sum;
    return sum + toNumber(pit?.volume);
  }, 0);

  return round2(Math.min(totalWater, Math.max(0, adjustedActivePitVolume)));
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
    endVolDelta: round2(endVolDelta),
    forceEndVolZero,
    activeDeltaByPit,
    storageDeltaByPit,
  };
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

      return res.status(200).json({
        success: true,
        message: "Pit updated successfully",
        data: item,
      });
    }

    item = await Pit.create(pitPayload);

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

    const [wellGeneral, casings, drillStrings, pits, distributionStates, consumeProducts, receivedMud, returnLostMud, addWaterEntries, otherVolAdditions, mudLossEntries, mudLossStorageEntries, transferMudEntries, emptyFluidEntries] =
      await Promise.all([
        findScopedWellGeneral({
          wellId,
          reportId: reportMeta.reportId,
          reportNo: reportMeta.reportNo,
        }),
        findScopedCasings({ wellId, reportId: reportMeta.reportId }),
        findScopedDrillStrings({ wellId, reportId: reportMeta.reportId }),
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
    const normalizedMudLossStorageEntries =
      normalizeMudLossStorageItems(mudLossStorageEntries);
    const normalizedAddWaterEntries = normalizeAddWaterItems(addWaterEntries);

    const md = toNumber(wellGeneral?.md);

    const validCasings = casings.filter((row) => toNumber(row.id) > 0);
    const latestCasing = validCasings.length
      ? validCasings[validCasings.length - 1]
      : null;

    const casingId = toNumber(latestCasing?.id);
    const hole = calculateHoleVolume(latestCasing, md);
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
    const heldVolDifference = round2(hole - previousHole);
    const drillstringVolume = Number(
      drillStrings
        .reduce(
          (sum, item) =>
            sum +
            calculatePipeVolume({
              id: item?.id,
              length: item?.length,
            }),
          0
        )
        .toFixed(2)
    );
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
      otherVolAdditions,
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
    const derivedActiveSystem = round2(activePitsWithTransfer + heldVolDifference);
    const activeSystem = derivedActiveSystem;
    const adjustedActiveSystemWater = calculateAdjustedActiveSystemWater({
      addWaterEntries: normalizedAddWaterEntries,
      activeSystemDistributionRows: distributionActiveSystemRows,
      activePitsList,
    });
    const activeSystemPendingInput = round2(
      operationVolumeEffects.addWaterActiveSystemDelta + activeSystemVolume
    );
    const pendingActiveSystemWater = round2(
      Math.max(0, activeSystemPendingInput - adjustedActiveSystemWater)
    );
    const effectiveEndVolDelta = round2(
      operationVolumeEffects.endVolDelta -
        operationVolumeEffects.addWaterActiveSystemDelta +
        pendingActiveSystemWater
    );
    const operationEndVol = operationVolumeEffects.forceEndVolZero
      ? 0
      : round2(derivedActiveSystem + effectiveEndVolDelta);
    const endVolBase = derivedActiveSystem;
    const endVol = operationVolumeEffects.forceEndVolZero
      ? 0
      : endVolBase > 0
        ? round2(endVolBase + effectiveEndVolDelta)
        : Math.abs(effectiveEndVolDelta) >= 0.005
          ? operationEndVol
          : 0;
    const endVolMinusActiveSystem = Number(
      (endVol - activeSystem).toFixed(2)
    );

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
      otherVolAdditions.reduce((sum, item) => sum + toNumber(item.totalVolume), 0).toFixed(2)
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
          pendingActiveSystemWater,
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
