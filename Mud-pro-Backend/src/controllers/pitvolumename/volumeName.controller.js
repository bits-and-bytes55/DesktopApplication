import WellGeneral from "../../modules/wellGeneral/wellGeneralModel.js";
import Casing from "../../modules/casing/casing.model.js";
import Pit from "../../modules/pit/pit.model.js";
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

const getWellId = (req) => String(req.params.wellId || "").trim();
const getReportId = (req) =>
  String(req.query.reportId ?? req.body?.reportId ?? "").trim();
const getReportNo = (req) =>
  String(req.query.reportNo ?? req.body?.reportNo ?? "").trim();

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

const calculateHoleVolume = (casing, mdInFeet) => {
  const id = toNumber(casing?.id);
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

const findScopedPits = async ({ wellId, reportId }) => {
  if (reportId) {
    const scopedPits = await Pit.find({ wellId, reportId }).sort({
      createdAt: 1,
      _id: 1,
    });

    const legacyPits = await Pit.find(legacyScopeFilter(wellId)).sort({
      createdAt: -1,
      _id: -1,
    });

    if (scopedPits.length === 0) {
      return dedupeLatestPits(legacyPits);
    }

    return mergeScopedWithLegacy(scopedPits, legacyPits);
  }

  return Pit.find({ wellId }).sort({ createdAt: 1, _id: 1 });
};

const findScopedConsumeProductDistributionState = async ({
  wellId,
  reportId,
}) => {
  if (reportId) {
    const scopedState = await ConsumeProductDistributionState.findOne({
      wellId,
      reportId,
    }).sort({ updatedAt: -1, createdAt: -1 });

    if (scopedState) {
      return scopedState;
    }

    return ConsumeProductDistributionState.findOne(legacyScopeFilter(wellId)).sort({
      updatedAt: -1,
      createdAt: -1,
    });
  }

  return ConsumeProductDistributionState.findOne({ wellId }).sort({
    updatedAt: -1,
    createdAt: -1,
  });
};

const cleanDistributionRows = (items = []) =>
  items
    .map((item) => ({
      pitName: toText(item?.pitName),
      volume: Number(toNumber(item?.volume).toFixed(2)),
    }))
    .filter((item) => item.pitName && item.volume > 0);

const buildCalculatedVolumeMap = (distributionRows = []) => {
  const calculatedVolumeByPit = new Map();
  let activeSystemVolume = 0;

  for (const row of distributionRows) {
    const key = toText(row.pitName).toLowerCase();
    if (!key) continue;

    if (key === "active system") {
      activeSystemVolume = Number((activeSystemVolume + toNumber(row.volume)).toFixed(2));
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
  };
};

const isActiveSystemName = (value) =>
  toText(value).toLowerCase() === "active system";

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

const buildOperationVolumeEffects = ({
  receivedMud = [],
  returnLostMud = [],
  addWaterEntries = [],
  otherVolAdditions = [],
  mudLossEntries = [],
  mudLossStorageEntries = [],
  transferMudEntries = [],
  emptyFluidEntries = [],
}) => {
  let activeSystemDelta = 0;
  const storageDeltaByPit = new Map();

  for (const item of addWaterEntries) {
    const volume = toNumber(item.volume);
    if (isActiveSystemName(item.to)) {
      activeSystemDelta += volume;
    } else {
      addPitDelta(storageDeltaByPit, item.to, volume);
    }
  }

  for (const item of receivedMud) {
    const volume = toNumber(item.netVolume);
    if (isActiveSystemName(item.to)) {
      activeSystemDelta += volume;
    } else {
      addPitDelta(storageDeltaByPit, item.to, volume);
    }
  }

  for (const item of returnLostMud) {
    const returned = toNumber(item.volReturned);
    const lost = toNumber(item.volLost);
    const totalDeduct = round2(returned + lost);

    if (isActiveSystemName(item.from)) {
      activeSystemDelta -= totalDeduct;
    } else {
      addPitDelta(storageDeltaByPit, item.from, -totalDeduct);
    }

    if (isActiveSystemName(item.to)) {
      activeSystemDelta += returned;
    } else if (!isIgnoredDestination(item.to)) {
      addPitDelta(storageDeltaByPit, item.to, returned);
    }
  }

  for (const item of otherVolAdditions) {
    activeSystemDelta += toNumber(item.totalVolume);
  }

  for (const item of mudLossEntries) {
    activeSystemDelta -= toNumber(item.totalLoss);
  }

  for (const item of mudLossStorageEntries) {
    addPitDelta(storageDeltaByPit, item.storage, -toNumber(item.totalLoss));
  }

  for (const item of transferMudEntries) {
    const transfers = Array.isArray(item.transfers) ? item.transfers : [];
    const totalTransferVol =
      toNumber(item.totalTransferVol) ||
      transfers.reduce((sum, row) => sum + toNumber(row?.volume), 0);

    if (isActiveSystemName(item.from)) {
      activeSystemDelta -= totalTransferVol;
      for (const row of transfers) {
        addPitDelta(storageDeltaByPit, row?.pitName, toNumber(row?.volume));
      }
    } else {
      addPitDelta(storageDeltaByPit, item.from, -totalTransferVol);
      activeSystemDelta += totalTransferVol;
    }
  }

  for (const item of emptyFluidEntries) {
    const volume = toNumber(item.volume || item.totalVolume);
    if (item.actionType === "Dump") {
      activeSystemDelta -= volume;
    } else if (item.actionType === "Transfer to Storage") {
      activeSystemDelta -= volume;
      addPitDelta(storageDeltaByPit, item.pitName, volume);
    }
  }

  return {
    activeSystemDelta: round2(activeSystemDelta),
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
      await ConsumeProductDistributionState.deleteMany(scopedOperationFilter({ wellId, reportId }));

      return res.status(200).json({
        success: true,
        message: "Consume product distribution cleared successfully",
        data: {
          wellId,
          reportId,
          inputMethod,
          addWaterEnabled: false,
          addWaterVolume: 0,
          totalVolume: 0,
          distributions: [],
        },
      });
    }

    const item = await ConsumeProductDistributionState.findOneAndUpdate(
      scopedOperationFilter({ wellId, reportId }),
      {
        wellId,
        reportId,
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

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const reportMeta = await resolveReportMeta({ wellId, reportId, reportNo });

    const [wellGeneral, casings, pits, distributionState, consumeProducts, receivedMud, returnLostMud, addWaterEntries, otherVolAdditions, mudLossEntries, mudLossStorageEntries, transferMudEntries, emptyFluidEntries] =
      await Promise.all([
        findScopedWellGeneral({
          wellId,
          reportId: reportMeta.reportId,
          reportNo: reportMeta.reportNo,
        }),
        findScopedCasings({ wellId, reportId: reportMeta.reportId }),
        findScopedPits({ wellId, reportId: reportMeta.reportId }),
        findScopedConsumeProductDistributionState({
          wellId,
          reportId: reportMeta.reportId,
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

    const md = toNumber(wellGeneral?.md);

    const validCasings = casings.filter((row) => toNumber(row.id) > 0);
    const latestCasing = validCasings.length
      ? validCasings[validCasings.length - 1]
      : null;

    const casingId = toNumber(latestCasing?.id);
    const hole = calculateHoleVolume(latestCasing, md);

    const activePitsList = pits.filter((pit) => pit.initialActive === true);
    const storagePitsList = pits.filter((pit) => pit.initialActive === false);

    const activePits = Number(
      activePitsList.reduce((sum, pit) => sum + toNumber(pit.volume), 0).toFixed(2)
    );

    const totalStorage = Number(
      storagePitsList.reduce((sum, pit) => sum + toNumber(pit.volume), 0).toFixed(2)
    );

    const distributionRows = cleanDistributionRows(distributionState?.distributions ?? []);
    const { activeSystemVolume, calculatedVolumeByPit } =
      buildCalculatedVolumeMap(distributionRows);
    const operationVolumeEffects = buildOperationVolumeEffects({
      receivedMud,
      returnLostMud,
      addWaterEntries,
      otherVolAdditions,
      mudLossEntries,
      mudLossStorageEntries,
      transferMudEntries,
      emptyFluidEntries,
    });
    for (const [pitName, volume] of operationVolumeEffects.storageDeltaByPit) {
      addPitDelta(calculatedVolumeByPit, pitName, volume);
    }
    const derivedActiveSystem = Number((activePits + hole).toFixed(2));
    // Legacy desktop behavior:
    // Active System = measured Active Pits + Hole
    // End Vol. = consume-product distribution's "Active System" row when present;
    // the legacy Pit table keeps it at zero until an end volume is supplied.
    // Storage calculated volumes come from the remaining distribution rows
    const activeSystem = derivedActiveSystem;
    const operationEndVol = round2(
      activeSystem + operationVolumeEffects.activeSystemDelta
    );
    const endVol =
      activeSystemVolume > 0
        ? activeSystemVolume
        : Math.abs(operationVolumeEffects.activeSystemDelta) >= 0.005
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
      addWaterEntries.reduce((sum, item) => sum + toNumber(item.volume), 0).toFixed(2)
    );

    const mudLossTotal = Number(
      mudLossEntries.reduce((sum, item) => sum + toNumber(item.totalLoss), 0).toFixed(2)
    );

    const mudLossStorageTotal = Number(
      mudLossStorageEntries.reduce((sum, item) => sum + toNumber(item.totalLoss), 0).toFixed(2)
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

    const heldVolDifference = hole;

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
        volumeName: {
          heldVolDifference,
          hole,
          activePits,
          activeSystem,
          endVol,
          endVolMinusActiveSystem,
          totalStorage,
          totalOnLocation,
          ledgerTotalOnLocation,
          previousTotalOnLocation: 0,
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
          operationEndVol,
        },
        consumeProductDistribution: {
          inputMethod: toText(distributionState?.inputMethod) || "Used",
          addWaterEnabled: Boolean(distributionState?.addWaterEnabled),
          addWaterVolume: Number(
            toNumber(distributionState?.addWaterVolume).toFixed(2)
          ),
          totalVolume: Number(toNumber(distributionState?.totalVolume).toFixed(2)),
          activeSystemVolume,
          distributions: distributionRows,
        },
        activePitsTable: activePitsList.map((pit) => ({
          _id: pit._id,
          pitName: pit.pitName,
          measuredVol: toNumber(pit.volume),
          mw: toNumber(pit.density),
          mud: pit.fluidType || "",
          reportId: pit.reportId || "",
        })),
        storageTable: storagePitsList.map((pit) => ({
          _id: pit._id,
          pitName: pit.pitName,
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
