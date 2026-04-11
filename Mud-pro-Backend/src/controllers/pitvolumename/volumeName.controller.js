import WellGeneral from "../../modules/wellGeneral/wellGeneralModel.js";
import Casing from "../../modules/casing/casing.model.js";
import Pit from "../../modules/pit/pit.model.js";
import ConsumeProduct from "../../modules/Consumeproduct/ConsumeProduct.js";
import ReceiveMud from "../../modules/receivemud/ReceiveMud.js";
import ReturnLostMud from "../../modules/returnlostmud/ReturnLostMud.js";
import AddWater from "../../modules/addwater/AddWater.js";
import OtherVolAddition from "../../modules/othervol/OtherVolAddition.js";
import MudLoss from "../../modules/mudloss/MudLoss.js";
import MudLossStorage from "../../modules/mudlossstorage/MudLossStorage.js";
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

const calculateHoleVolume = (idInInches, mdInFeet) => {
  const id = toNumber(idInInches);
  const md = toNumber(mdInFeet);

  if (id <= 0 || md <= 0) return 0;

  return Number(((id * id * md) / 1029.4).toFixed(2));
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

    const {
      product,
      code,
      sg,
      unit,
      price,
      initial,
      adjust,
      used,
      final,
      cost,
      volumeBbl,
    } = req.body;

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const item = await ConsumeProduct.create({
      wellId,
      product: product || "",
      code: code || "",
      sg: sg === null || sg === undefined || sg === "" ? null : Number(sg),
      unit: unit || "",
      price: Number(price) || 0,
      initial: Number(initial) || 0,
      adjust: Number(adjust) || 0,
      used: Number(used) || 0,
      final: Number(final) || 0,
      cost: Number(cost) || 0,
      volumeBbl: Number(volumeBbl) || 0,
    });

    return res.status(201).json({
      success: true,
      message: "Consume product saved successfully",
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

    const [wellGeneral, casings, pits, consumeProducts, receivedMud, returnLostMud, addWaterEntries, otherVolAdditions, mudLossEntries, mudLossStorageEntries] =
      await Promise.all([
        findScopedWellGeneral({
          wellId,
          reportId: reportMeta.reportId,
          reportNo: reportMeta.reportNo,
        }),
        Casing.find({ wellId }).sort({ createdAt: 1 }),
        findScopedPits({ wellId, reportId: reportMeta.reportId }),
        ConsumeProduct.find({ wellId }).sort({ createdAt: 1 }),
        ReceiveMud.find({ wellId }).sort({ createdAt: 1 }),
        ReturnLostMud.find({ wellId }).sort({ createdAt: 1 }),
        AddWater.find({ wellId }).sort({ createdAt: 1 }),
        OtherVolAddition.find({ wellId }).sort({ createdAt: 1 }),
        MudLoss.find({ wellId }).sort({ createdAt: 1 }),
        MudLossStorage.find({ wellId }).sort({ createdAt: 1 }),
      ]);

    const md = toNumber(wellGeneral?.md);

    const validCasings = casings.filter((row) => toNumber(row.id) > 0);
    const latestCasing = validCasings.length
      ? validCasings[validCasings.length - 1]
      : null;

    const casingId = toNumber(latestCasing?.id);
    const hole = calculateHoleVolume(casingId, md);

    const activePitsList = pits.filter((pit) => pit.initialActive === true);
    const storagePitsList = pits.filter((pit) => pit.initialActive === false);

    const activePits = Number(
      activePitsList.reduce((sum, pit) => sum + toNumber(pit.volume), 0).toFixed(2)
    );

    const totalStorage = Number(
      storagePitsList.reduce((sum, pit) => sum + toNumber(pit.volume), 0).toFixed(2)
    );

    const activeSystem = Number((activePits + hole).toFixed(2));
    const endVol = activeSystem;
    const endVolMinusActiveSystem = 0;

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

    const totalOnLocation = Number(
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
        },
        totalsBreakdown: {
          consumeProductTotal,
          receivedMudTotal,
          addWaterTotal,
          otherVolAdditionTotal,
          lostMudTotal,
          mudLossTotal,
          mudLossStorageTotal,
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
          calculatedVol: 0,
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
