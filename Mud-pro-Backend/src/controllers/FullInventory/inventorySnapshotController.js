import InventorySnapshot from "../../modules/FullInventory/InventorySnapshot.js";
import ConsumeProduct from "../../modules/Consumeproduct/ConsumeProduct.js";
import ReceiveProduct from "../../modules/ReceiveProduct/Product/ReceiveProduct.js";
import ReturnProduct from "../../modules/ReturnProduct/Product/ReturnProduct.js";
import Service from "../../modules/ConsumeServices/Services/Service.js";
import Engineering from "../../modules/ConsumeServices/Engineers/Engineering.js";
import Package from "../../modules/ConsumeServices/Package/Package.js";
import ReceivePackage from "../../modules/ReceiveProduct/Package/ReceivePackage.js";
import ReturnPackage from "../../modules/ReturnProduct/Package/ReturnPackage.js";
import ConsumeProductDistributionState from "../../modules/Consumeproduct/ConsumeProductDistributionState.js";
import UgInventorySnapshot from "../../modules/ugInventory/ugInventoryProductModel.js";
import Well from "../../modules/well/well.model.js";
import Report from "../../modules/report/report.model.js";
import WellGeneral from "../../modules/wellGeneral/wellGeneralModel.js";
import Casing from "../../modules/casing/casing.model.js";
import { loadMergedPits } from "../../utils/pitReportState.js";
import {
  buildScopedFilter,
  legacyReportScope,
  readReportId,
  readWellId,
  toText,
} from "../../utils/reportScope.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const parsed = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(parsed) ? parsed : 0;
};

const round2 = (value) => Number(toNumber(value).toFixed(2));

const normalizeText = (value) => String(value || "").trim().toLowerCase();

const SOLID_BAG_KG = 25;
const LIQUID_DRUM_GAL = 55;
const LIQUID_SG = 1;
const GAL_TO_LITER = 3.78541;
const KG_TO_LB = 2.20462;

const keyFromCodeOrName = (code, name, fallback) => {
  const cleanCode = normalizeText(code);
  if (cleanCode) return `code:${cleanCode}`;

  const cleanName = normalizeText(name);
  if (cleanName) return `name:${cleanName}`;

  return fallback;
};

const summaryFromRows = (rows = []) => {
  const first = rows[0] || {};
  return {
    subtotal: round2(rows.reduce((sum, row) => sum + toNumber(row.subtotal), 0)),
    taxRate: round2(first.taxRate),
    taxAmount: round2(first.taxAmount),
    dailyTotal: round2(first.dailyTotal || first.totalDollar),
    prevTotal: round2(first.prevTotal),
    cumTotal: round2(first.cumTotal || first.totalDollar),
    intervalTotal: round2(first.intervalTotal),
    stockBalance: round2(first.stockBalance),
    bulkTankSetupFee: round2(first.bulkTankSetupFee),
  };
};

const isVolumeNameWaterHelper = (item) =>
  normalizeText(item.product) === "water" &&
  normalizeText(item.code) === "" &&
  normalizeText(item.unit) === "" &&
  toNumber(item.price) === 0 &&
  toNumber(item.initial) === 0 &&
  toNumber(item.adjust) === 0 &&
  toNumber(item.used) === 0 &&
  toNumber(item.final) === 0 &&
  toNumber(item.cost) === 0 &&
  toNumber(item.volumeBbl) > 0;

const reportOrderNumber = (report = {}) => {
  const parsed = Number(toText(report.userReportNo || report.reportNo));
  return Number.isFinite(parsed) ? parsed : null;
};

const reportTimeValue = (report = {}) =>
  new Date(report.reportDate || report.createdAt || report.updatedAt || 0).getTime() || 0;

const sortReportsOldestFirst = (reports = []) =>
  [...reports].sort((left, right) => {
    const leftNumber = reportOrderNumber(left);
    const rightNumber = reportOrderNumber(right);
    if (leftNumber !== null && rightNumber !== null && leftNumber !== rightNumber) {
      return leftNumber - rightNumber;
    }

    const timeDiff = reportTimeValue(left) - reportTimeValue(right);
    if (timeDiff !== 0) return timeDiff;
    return toText(left._id).localeCompare(toText(right._id));
  });

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

  return length > 0 ? round2((id * id * length) / 1029.4) : 0;
};

const packSize = (unit = "") => {
  const match = String(unit).match(/-?\d+(?:\.\d+)?/);
  return match ? toNumber(match[0]) || 1 : 1;
};

const concentrationBasisForUnit = (unit = "") => {
  const normalized = normalizeText(unit);
  const amount = packSize(unit);
  if (amount <= 0) return null;

  if (normalized.includes("bag")) {
    return {
      factorPerPack: SOLID_BAG_KG * KG_TO_LB,
      concentrationUnit: "lb/bbl",
    };
  }
  if (normalized.includes("drum")) {
    return {
      factorPerPack: LIQUID_DRUM_GAL * GAL_TO_LITER * LIQUID_SG * KG_TO_LB,
      concentrationUnit: "lb/bbl",
    };
  }
  if (normalized.includes("gal")) {
    return {
      factorPerPack: amount * GAL_TO_LITER * LIQUID_SG * KG_TO_LB,
      concentrationUnit: "lb/bbl",
    };
  }
  if (normalized.includes("ton") || normalized === "mt" || normalized.endsWith(" mt")) {
    return { factorPerPack: amount * 1000 * KG_TO_LB, concentrationUnit: "lb/bbl" };
  }
  if (normalized.includes("kg")) {
    return { factorPerPack: amount * KG_TO_LB, concentrationUnit: "lb/bbl" };
  }
  if (normalized.includes("lb")) {
    return { factorPerPack: amount, concentrationUnit: "lb/bbl" };
  }
  if (normalized.includes(" bbl") || normalized.startsWith("bbl")) {
    return { factorPerPack: amount * 42, concentrationUnit: "gal/bbl" };
  }
  if (normalized.includes(" m3") || normalized.startsWith("m3")) {
    return { factorPerPack: amount * 264.172, concentrationUnit: "gal/bbl" };
  }
  if (normalized.includes("ml")) {
    return {
      factorPerPack: amount * 0.000264172,
      concentrationUnit: "gal/bbl",
    };
  }
  if (normalized.includes(" l") || normalized.startsWith("l")) {
    return { factorPerPack: amount * 0.264172, concentrationUnit: "gal/bbl" };
  }

  return null;
};

const findScopedWellGeneral = async ({ wellId, reportId, reportNo }) => {
  if (reportId) {
    const byReportId = await WellGeneral.findOne({ wellId, reportId })
      .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
      .lean();
    if (byReportId) return byReportId;
  }

  if (reportNo) {
    const byReportNo = await WellGeneral.findOne({ wellId, reportNo })
      .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
      .lean();
    if (byReportNo) return byReportNo;
  }

  const legacy = await WellGeneral.findOne({
    wellId,
    ...legacyReportScope(),
  })
    .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
    .lean();
  if (legacy) return legacy;

  return WellGeneral.findOne({ wellId })
    .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
    .lean();
};

const findScopedCasings = async ({ wellId, reportId }) => {
  const filter = reportId
    ? {
        wellId,
        $or: [{ reportId }, { reportId: { $exists: false } }, { reportId: null }, { reportId: "" }],
      }
    : { wellId };

  return Casing.find(filter).sort({ createdAt: 1, _id: 1 }).lean();
};

const findPreviousReport = async ({ wellId, reportId }) => {
  if (!wellId || !reportId) return null;

  const reports = sortReportsOldestFirst(await Report.find({ wellId }).lean());
  const index = reports.findIndex((item) => toText(item._id) === reportId);
  return index > 0 ? reports[index - 1] : null;
};

const findPreviousReportDailyTotal = async ({ wellId, reportId }) => {
  const previousReport = await findPreviousReport({ wellId, reportId });
  if (!previousReport) return 0;

  const rows = await InventorySnapshot.find({
    wellId,
    reportId: toText(previousReport._id),
  }).lean();

  return summaryFromRows(rows).dailyTotal;
};

const resolveConcentrationVolumeBasis = async ({ wellId, reportId, reportNo }) => {
  if (!wellId || !reportId) return 0;

  const [distributionState, wellGeneral, casings, pits] = await Promise.all([
    ConsumeProductDistributionState.findOne({ wellId, reportId })
      .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
      .lean(),
    findScopedWellGeneral({ wellId, reportId, reportNo }),
    findScopedCasings({ wellId, reportId }),
    loadMergedPits({ wellId, reportId, initialActive: true }),
  ]);

  const distributedTotal = round2(distributionState?.totalVolume);
  if (distributedTotal > 0) {
    return distributedTotal;
  }

  const md = toNumber(wellGeneral?.md);
  const validCasings = casings.filter((row) => toNumber(row.id) > 0);
  const latestCasing = validCasings.length
    ? validCasings[validCasings.length - 1]
    : null;
  const hole = calculateHoleVolume(latestCasing, md);
  const activeSystem = round2(
    pits.reduce((sum, pit) => sum + toNumber(pit.volume), 0) + hole
  );

  return activeSystem > 0 ? activeSystem : 0;
};

const buildPreviousConcentrationMap = async ({ wellId, reportId }) => {
  const previousReport = await findPreviousReport({ wellId, reportId });
  if (!previousReport) {
    return new Map();
  }

  const rows = await InventorySnapshot.find({
    wellId,
    reportId: toText(previousReport._id),
    category: "Product",
  }).lean();

  return new Map(
    rows.map((row, index) => [
      keyFromCodeOrName(row.code, row.itemName, `previous:${index}`),
      row,
    ])
  );
};

export const generateInventorySnapshot = async (req, res) => {
  try {
    const wellId = readWellId(req);
    const reportId = readReportId(req);
    console.log(
      `[BACKEND] Starting generateInventorySnapshot for wellId=${wellId || "global"} reportId=${reportId || "legacy"}`
    );

    const consumeFilter = wellId
      ? buildScopedFilter(wellId, reportId)
      : reportId
        ? { reportId }
        : {};
    const rawConsumes = await ConsumeProduct.find(consumeFilter)
      .sort({ sortOrder: 1, createdAt: 1, _id: 1 })
      .lean();
    const consumes = rawConsumes.filter((item) => !isVolumeNameWaterHelper(item));
    const sourceFilter = consumeFilter;

    const receives = await ReceiveProduct.find(sourceFilter).lean();
    const returns = await ReturnProduct.find(sourceFilter).lean();
    const services = await Service.find(sourceFilter).lean();
    const engineering = await Engineering.find(sourceFilter).lean();
    const packages = await Package.find(sourceFilter).lean();
    const packageReceives = await ReceivePackage.find(sourceFilter).lean();
    const packageReturns = await ReturnPackage.find(sourceFilter).lean();

    const previousDailyTotal =
      wellId && reportId
        ? await findPreviousReportDailyTotal({ wellId, reportId })
        : 0;

    const inventoryConfig = wellId
      ? await UgInventorySnapshot.findOne({ wellId }).sort({ updatedAt: -1 }).lean()
      : null;
    const wellConfig = wellId ? await Well.findById(wellId).lean() : null;
    const currentReport = reportId
      ? await Report.findById(reportId).lean().catch(() => null)
      : null;

    const taxRate = round2(inventoryConfig?.taxRate);
    const bulkTankSetupFee = round2(
      inventoryConfig?.bulkTankSetupFee || wellConfig?.bulkTankSetupFee
    );

    let snapshotData = [];

    const productKeys = [
      ...new Set([
        ...receives.map((row, index) =>
          keyFromCodeOrName(row.code, row.productName, `receive:${index}`)
        ),
        ...consumes.map((row, index) =>
          keyFromCodeOrName(row.code, row.product, `consume:${index}`)
        ),
        ...returns.map((row, index) =>
          keyFromCodeOrName(row.code, row.productName, `return:${index}`)
        ),
      ]),
    ];

    for (const key of productKeys) {
      const productReceives = receives.filter(
        (row, index) =>
          keyFromCodeOrName(row.code, row.productName, `receive:${index}`) === key
      );
      const productConsumes = consumes.filter(
        (row, index) =>
          keyFromCodeOrName(row.code, row.product, `consume:${index}`) === key
      );
      const productReturns = returns.filter(
        (row, index) =>
          keyFromCodeOrName(row.code, row.productName, `return:${index}`) === key
      );

      const cumulativeRec = round2(
        productReceives.reduce((sum, row) => sum + toNumber(row.amount), 0)
      );
      const cumulativeUsed = round2(
        productConsumes.reduce((sum, row) => sum + toNumber(row.used), 0)
      );
      const cumulativeRet = round2(
        productReturns.reduce((sum, row) => sum + toNumber(row.amount), 0)
      );
      const cumulativeAdj = round2(
        productConsumes.reduce((sum, row) => sum + toNumber(row.adjust), 0)
      );

      const price = round2(productConsumes[0]?.price);
      const initial = round2(productConsumes[0]?.initial);

      const itemName =
        productReceives[0]?.productName ||
        productConsumes[0]?.product ||
        productReturns[0]?.productName ||
        "";

      const code =
        productReceives[0]?.code ||
        productConsumes[0]?.code ||
        productReturns[0]?.code ||
        "";

      const unit =
        productReceives[0]?.unit ||
        productConsumes[0]?.unit ||
        productReturns[0]?.unit ||
        "";

      const finalVal = round2(
        initial + cumulativeRec - cumulativeRet - cumulativeUsed - cumulativeAdj
      );
      const subtotal = round2(cumulativeUsed * price);

      snapshotData.push({
        wellId,
        reportId,
        category: "Product",
        itemName,
        code,
        unit,
        price,
        cumulativeRec,
        cumulativeRet,
        cumulativeUsed,
        initial,
        rec: cumulativeRec,
        ret: cumulativeRet,
        adj: cumulativeAdj,
        used: cumulativeUsed,
        final: finalVal,
        subtotal,
        costDollar: subtotal,
        sortOrder: toNumber(productConsumes[0]?.sortOrder),
      });
    }

    for (const srv of services) {
      const subtotal = round2(toNumber(srv.price) * toNumber(srv.usage));
      snapshotData.push({
        wellId,
        reportId,
        category: "Service",
        itemName: srv.serviceName || "",
        code: srv.code || "",
        unit: srv.unit || "",
        price: round2(srv.price),
        cumulativeUsed: round2(srv.usage),
        used: round2(srv.usage),
        final: 0,
        subtotal,
        costDollar: subtotal,
      });
    }

    for (const eng of engineering) {
      const subtotal = round2(toNumber(eng.price) * toNumber(eng.usage));
      snapshotData.push({
        wellId,
        reportId,
        category: "Engineering",
        itemName: eng.engineeringName || "",
        code: eng.code || "",
        unit: eng.unit || "",
        price: round2(eng.price),
        cumulativeUsed: round2(eng.usage),
        used: round2(eng.usage),
        final: 0,
        subtotal,
        costDollar: subtotal,
      });
    }

    const packageKeys = [
      ...new Set([
        ...packageReceives.map((row, index) =>
          keyFromCodeOrName(row.code, row.packageName, `pkg-receive:${index}`)
        ),
        ...packages.map((row, index) =>
          keyFromCodeOrName(row.code, row.packageName, `pkg-consume:${index}`)
        ),
        ...packageReturns.map((row, index) =>
          keyFromCodeOrName(row.code, row.packageName, `pkg-return:${index}`)
        ),
      ]),
    ];

    for (const key of packageKeys) {
      const rec = packageReceives.filter(
        (row, index) =>
          keyFromCodeOrName(row.code, row.packageName, `pkg-receive:${index}`) ===
          key
      );
      const cons = packages.filter(
        (row, index) =>
          keyFromCodeOrName(row.code, row.packageName, `pkg-consume:${index}`) ===
          key
      );
      const ret = packageReturns.filter(
        (row, index) =>
          keyFromCodeOrName(row.code, row.packageName, `pkg-return:${index}`) ===
          key
      );

      const cumulativeRec = round2(
        rec.reduce((sum, row) => sum + toNumber(row.amount), 0)
      );
      const cumulativeUsed = round2(
        cons.reduce((sum, row) => sum + toNumber(row.used), 0)
      );
      const cumulativeRet = round2(
        ret.reduce((sum, row) => sum + toNumber(row.amount), 0)
      );
      const cumulativeAdj = round2(
        cons.reduce((sum, row) => sum + toNumber(row.adjust), 0)
      );

      const initial = round2(cons[0]?.initial);
      const price = round2(cons[0]?.price);
      const subtotal = round2(cumulativeUsed * price);
      const finalVal = round2(
        initial + cumulativeRec - cumulativeRet - cumulativeUsed + cumulativeAdj
      );

      snapshotData.push({
        wellId,
        reportId,
        category: "Package",
        itemName: cons[0]?.packageName || rec[0]?.packageName || "",
        code: cons[0]?.code || rec[0]?.code || ret[0]?.code || "",
        unit: cons[0]?.unit || rec[0]?.unit || ret[0]?.unit || "",
        price,
        cumulativeRec,
        cumulativeUsed,
        cumulativeRet,
        initial,
        rec: cumulativeRec,
        ret: cumulativeRet,
        adj: cumulativeAdj,
        used: cumulativeUsed,
        final: finalVal,
        subtotal,
        costDollar: subtotal,
      });
    }

    if (wellId && reportId) {
      const previousConcentrationMap = await buildPreviousConcentrationMap({
        wellId,
        reportId,
      });
      const concentrationVolumeBasis = await resolveConcentrationVolumeBasis({
        wellId,
        reportId,
        reportNo: currentReport?.reportNo,
      });

      snapshotData = snapshotData.map((item, index) => {
        if (item.category !== "Product") {
          return item;
        }

        const basis = concentrationBasisForUnit(item.unit);
        const rowKey = keyFromCodeOrName(item.code, item.itemName, `product:${index}`);
        const previous = previousConcentrationMap.get(rowKey) || {};
        const previousEndConcentration = round2(previous.endingConcentration);
        const previousAmount =
          toNumber(previous.concentrationSourceAmount) > 0
            ? toNumber(previous.concentrationSourceAmount)
            : toNumber(previous.endingConcentration) *
              toNumber(previous.concentrationVolumeBasis);
        const currentAmount = basis
          ? round2(toNumber(item.used) * basis.factorPerPack)
          : 0;
        const endingAmount = round2(previousAmount + currentAmount);
        const endingConcentration =
          basis && concentrationVolumeBasis > 0
            ? round2(endingAmount / concentrationVolumeBasis)
            : previousEndConcentration;

        return {
          ...item,
          concentrationUnit: basis?.concentrationUnit || "",
          concentrationVolumeBasis,
          concentrationSourceAmount: endingAmount,
          startingConcentration: previousEndConcentration,
          endingConcentration,
        };
      });
    }

    const subtotal = round2(
      snapshotData.reduce((sum, item) => sum + toNumber(item.subtotal), 0)
    );
    const taxAmount = round2(subtotal * (taxRate / 100));
    const dailyTotal = round2(subtotal + taxAmount);
    const prevTotal = previousDailyTotal;
    const cumTotal = round2(prevTotal + dailyTotal);
    const intervalTotal = dailyTotal;
    const stockBalance = round2(
      snapshotData.reduce(
        (sum, item) => sum + toNumber(item.final) * toNumber(item.price),
        0
      )
    );

    snapshotData = snapshotData.map((item) => ({
      ...item,
      totalDollar: dailyTotal,
      taxRate,
      taxAmount,
      dailyTotal,
      prevTotal,
      cumTotal,
      intervalTotal,
      stockBalance,
      bulkTankSetupFee,
    }));

    await InventorySnapshot.deleteMany(
      wellId
        ? { wellId, ...(reportId ? { reportId } : {}) }
        : reportId
          ? { reportId }
          : {}
    );
    if (snapshotData.length) {
      await InventorySnapshot.insertMany(snapshotData);
    }

    return res.status(200).json({
      success: true,
      message: "Inventory Snapshot Generated Successfully",
      count: snapshotData.length,
      data: snapshotData,
      summary: {
        subtotal,
        taxRate,
        taxAmount,
        dailyTotal,
        prevTotal,
        cumTotal,
        intervalTotal,
        stockBalance,
        bulkTankSetupFee,
      },
    });
  } catch (error) {
    console.error("generateInventorySnapshot error:", error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const getInventorySnapshot = async (req, res) => {
  try {
    const wellId = readWellId(req);
    const reportId = readReportId(req);
    const data = await InventorySnapshot.find(
      wellId
        ? { wellId, ...(reportId ? { reportId } : {}) }
        : reportId
          ? { reportId }
          : {}
    ).sort({
      category: 1,
      itemName: 1,
    });

    return res.status(200).json({
      success: true,
      count: data.length,
      data,
      summary: summaryFromRows(data),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
