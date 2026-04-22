import ExcelJS from "exceljs";
import { fileURLToPath } from "url";
import InventorySnapshot from "../../modules/FullInventory/InventorySnapshot.js";
import Pit from "../../modules/pit/pit.model.js";
import { Activity } from "../../modules/others/others.model.js";
import Well from "../../modules/well/well.model.js";
import Pad from "../../modules/pad/pad.model.js";
import WellGeneral from "../../modules/wellGeneral/wellGeneralModel.js";
import Report from "../../modules/report/report.model.js";
import DrillString from "../../modules/DrillString/DrillString.js";
import Casing from "../../modules/casing/casing.model.js";
import Pump from "../../modules/pump/pump.model.js";
import ConsumeProduct from "../../modules/Consumeproduct/ConsumeProduct.js";
import Service from "../../modules/ConsumeServices/Services/Service.js";
import Engineering from "../../modules/ConsumeServices/Engineers/Engineering.js";
import AddWater from "../../modules/addwater/AddWater.js";
import ReceiveMud from "../../modules/receivemud/ReceiveMud.js";
import ReturnLostMud from "../../modules/returnlostmud/ReturnLostMud.js";
import TransferMud from "../../modules/transfermud/TransferMud.js";
import OtherVolAddition from "../../modules/othervol/OtherVolAddition.js";
import MudLoss from "../../modules/mudloss/MudLoss.js";
import MudLossStorage from "../../modules/mudlossstorage/MudLossStorage.js";
import { Interval } from "../../modules/wellInterval/intervalModel.js";
import { loadMergedPits } from "../../utils/pitReportState.js";
import MudReportState from "../../modules/mudReport/MudReportState.js";
import SolidsAnalysis from "../../modules/SolidAnalysis/solidanalysismodel.js";
import { Shaker, OtherSce } from "../../modules/sce/sce.model.js";
import EmptyFluidActiveSystem from "../../modules/emptyfluidactivesystem/EmptyFluidActiveSystem.js";

const TEMPLATE_PATH = fileURLToPath(
  new URL("../../../assets/template.xlsx", import.meta.url)
);
const DMR_SHEET_NAME = "DMR";
const INVENTORY_SHEET_NAME = "Inventory";

const PRODUCT_ROWS = { start: 14, end: 63 };
const SERVICE_ROWS = { start: 76, end: 84 };
const ACTIVE_PIT_ROWS = { start: 77, end: 84 };
const TIME_ROWS = { start: 75, end: 84 };
const ENGINEERING_ROWS = { start: 87, end: 91 };
const RESERVE_ROWS = { start: 95, end: 101 };

const PRODUCT_COLUMNS = [
  "A",
  "F",
  "I",
  "K",
  "M",
  "O",
  "Q",
  "S",
  "U",
  "W",
  "Y",
  "AA",
  "AC",
  "AE",
];
const SERVICE_COLUMNS = ["A", "G", "I", "K"];
const PIT_COLUMNS = ["M", "S", "U", "W"];
const TIME_COLUMNS = ["AA", "AE"];

const SUMMARY_VALUE_CELLS = [
  "G67","J67","M67","G68","J68","M68","G69","J69","M69","G70","J70","M70",
  "G71","J71","M71","G72","J72","M72","G73","J73","M73","X67","AA67","AD67",
  "X68","AA68","AD68","X71","AA71","AD71","X72","AA72","AD72","X73","AA73","AD73",
];
const COST_SUMMARY_VALUE_CELLS = [
  "G94","G95","G96","G97","G98","G99","G100","G101",
];
const DMR_COST_VALUE_CELLS = ["P108","P109","P110","P111","P112","P113","P114","P115"];
const CUTTINGS_ANALYSIS_VALUE_CELLS = ["AE94","AE95","AE96","AE97"];

const toNumber = (value, fallback = 0) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};
const round = (value, digits = 2) =>
  Number(toNumber(value).toFixed(Math.max(0, digits)));
const roundOrBlank = (value, digits = 2) => {
  const raw = text(value);
  if (!raw) return "";
  const direct = Number(raw);
  const parsed = Number.isFinite(direct) ? direct : parseFraction(raw);
  if (parsed !== null && Number.isFinite(parsed) && Math.abs(parsed) < 0.01) return "";
  if (parsed !== null && Number.isFinite(parsed) && parsed <= 0) return "";
  const rounded = parsed === null || !Number.isFinite(parsed) ? null : round(parsed, digits);
  return rounded === null ? raw : rounded || "";
};
const text = (value, fallback = "") => {
  const parsed = value?.toString().trim();
  return parsed ? parsed : fallback;
};
const displayText = (value, fallback = "-") => text(value, fallback);
const firstText = (...values) => {
  for (const value of values) {
    const parsed = text(value);
    if (parsed) return parsed;
  }
  return "";
};
const meaningfulText = (value) => {
  const raw = text(value);
  if (!raw) return "";
  const direct = Number(raw);
  const parsed = Number.isFinite(direct) ? direct : parseFraction(raw);
  return parsed !== null && Number.isFinite(parsed) && (parsed <= 0 || Math.abs(parsed) < 0.01)
    ? ""
    : raw;
};
const firstMeaningfulText = (...values) => {
  for (const value of values) {
    const parsed = meaningfulText(value);
    if (parsed) return parsed;
  }
  return "";
};
const sumBy = (items, selector) =>
  items.reduce((sum, item) => sum + toNumber(selector(item)), 0);
const clamp = (value, min, max) => Math.min(Math.max(value, min), max);
const getReportDate = () =>
  new Date().toLocaleDateString("en-US", {
    month: "2-digit",
    day: "2-digit",
    year: "numeric",
  });
const formatDate = (value, fallback = "") => {
  if (!value) return fallback;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime())
    ? text(value, fallback)
    : parsed.toLocaleDateString("en-US");
};
const safeFilename = (value) =>
  text(value, "report").replace(/[<>:\"/\\\\|?*\\u0000-\\u001F]+/g, "_");
const legacyReportScope = () => ({
  $or: [{ reportId: { $exists: false } }, { reportId: null }],
});
const legacyReportScopeWithEmpty = () => ({
  $or: [{ reportId: { $exists: false } }, { reportId: null }, { reportId: "" }],
});
const legacyReportScopeForModel = (Model) => {
  const reportIdPath = Model?.schema?.path?.("reportId");
  return reportIdPath?.instance === "String"
    ? legacyReportScopeWithEmpty()
    : legacyReportScope();
};
const emptyFieldFilterForModel = (Model, field) => {
  const fieldPath = Model?.schema?.path?.(field);
  const includeEmptyString = !fieldPath || fieldPath.instance === "String";
  return {
    $or: [
      { [field]: { $exists: false } },
      { [field]: null },
      ...(includeEmptyString ? [{ [field]: "" }] : []),
    ],
  };
};
const getPitVolume = (pit) => pit.volume || pit.capacity || "";
const getActivePitVolume = (pit) => toNumber(pit.volume || pit.capacity);
const setCellValue = (ws, address, value = "") => {
  ws.getCell(address).value = value ?? "";
};
const normalizeUnit = (value, fallback = "") =>
  text(value, fallback)
    .replace(/Ã‚|Â/g, "")
    .replace(/[()]/g, "")
    .trim();
const unitSuffix = (value, fallback) => normalizeUnit(value, fallback) || fallback;
const parseFraction = (value) => {
  const clean = text(value).replace(/["']/g, "").trim();
  if (!clean) return null;
  const mixed = clean.match(/^(-?\d+)\s+(\d+)\/(\d+)$/);
  if (mixed) {
    const whole = Number(mixed[1]);
    const num = Number(mixed[2]);
    const den = Number(mixed[3]);
    if (Number.isFinite(whole) && Number.isFinite(num) && Number.isFinite(den) && den !== 0) {
      return whole + num / den;
    }
  }

  const simpleFraction = clean.match(/^(-?\d+)\/(\d+)$/);
  if (simpleFraction) {
    const num = Number(simpleFraction[1]);
    const den = Number(simpleFraction[2]);
    if (Number.isFinite(num) && Number.isFinite(den) && den !== 0) {
      return num / den;
    }
  }

  const numeric = clean.match(/-?\d+(?:\.\d+)?/);
  if (!numeric) return null;
  const parsed = Number(numeric[0]);
  return Number.isFinite(parsed) ? parsed : null;
};
const convertLength = (value, fromUnit, toUnit) => {
  const metersByUnit = {
    ft: 0.3048,
    m: 1,
    in: 0.0254,
    mm: 0.001,
    cm: 0.01,
    dm: 0.1,
  };
  const from = normalizeUnit(fromUnit).toLowerCase();
  const to = normalizeUnit(toUnit).toLowerCase();
  if (!from || !to || from === to) return toNumber(value);
  if (!(from in metersByUnit) || !(to in metersByUnit)) return toNumber(value);
  return (toNumber(value) * metersByUnit[from]) / metersByUnit[to];
};
const convertVolume = (value, fromUnit, toUnit) => {
  const cubicMetersByUnit = {
    bbl: 0.158987294928,
    m3: 1,
    l: 0.001,
    gal: 0.003785411784,
  };
  const from = normalizeUnit(fromUnit).toLowerCase();
  const to = normalizeUnit(toUnit).toLowerCase();
  if (!from || !to || from === to) return toNumber(value);
  if (!(from in cubicMetersByUnit) || !(to in cubicMetersByUnit)) {
    return toNumber(value);
  }
  return (toNumber(value) * cubicMetersByUnit[from]) / cubicMetersByUnit[to];
};
const normalizeIntervalKey = (value) =>
  text(value)
    .replace(/^\d+\.\s*/, "")
    .trim()
    .toLowerCase();
const resolveIntervalBitSize = (intervals, intervalName) => {
  const normalizedTarget = normalizeIntervalKey(intervalName);
  if (!intervals.length) return null;

  if (normalizedTarget) {
    const exact = intervals.find(
      (interval) => normalizeIntervalKey(interval.name) === normalizedTarget
    );
    const parsedExact = parseFraction(exact?.bitSize);
    if (parsedExact !== null) return parsedExact;
  }

  for (const interval of intervals) {
    const parsed = parseFraction(interval.bitSize);
    if (parsed !== null) return parsed;
  }

  return null;
};
const resolveIntervalBitSizeText = (intervals, intervalName) => {
  const normalizedTarget = normalizeIntervalKey(intervalName);

  if (normalizedTarget) {
    const exact = intervals.find(
      (interval) => normalizeIntervalKey(interval.name) === normalizedTarget
    );
    const exactBitSize = text(exact?.bitSize);
    if (exactBitSize) return exactBitSize;
  }

  const firstWithBitSize = intervals.find((interval) => text(interval.bitSize));
  return text(firstWithBitSize?.bitSize);
};
const hasCasingData = (casing = {}) =>
  firstText(casing.description, casing.type) ||
  [casing.od, casing.id, casing.bit, casing.toc].some(
    (value) => meaningfulText(value)
  );
const casingDataScore = (casing = {}) =>
  [
    casing.description,
    casing.type,
    casing.od,
    casing.top,
    casing.shoe,
    casing.bit,
    casing.toc,
  ].filter((value) => meaningfulText(value)).length;
const casingSignature = (casing = {}) =>
  [
    casing.description,
    casing.type,
    casing.od,
    casing.wt,
    casing.id,
    casing.top,
    casing.shoe,
    casing.bit,
    casing.toc,
  ]
    .map((value) => text(value).toLowerCase())
    .join("|");
const normalizeCasingRows = (casings = []) => {
  const bySignature = new Map();

  for (const casing of casings.filter(hasCasingData)) {
    const signature = casingSignature(casing);
    if (!signature) continue;
    const previous = bySignature.get(signature);
    const previousTime = new Date(previous?.updatedAt ?? previous?.createdAt ?? 0).getTime();
    const currentTime = new Date(casing?.updatedAt ?? casing?.createdAt ?? 0).getTime();
    if (!previous || currentTime >= previousTime) {
      bySignature.set(signature, casing);
    }
  }

  return Array.from(bySignature.values()).sort((left, right) => {
    const scoreDiff = casingDataScore(right) - casingDataScore(left);
    if (scoreDiff !== 0) return scoreDiff;
    return new Date(left?.createdAt ?? 0).getTime() - new Date(right?.createdAt ?? 0).getTime();
  });
};
const buildOpenHoleRow = ({ wellGeneral, intervals }) => {
  const bitSize = resolveIntervalBitSizeText(intervals, wellGeneral?.interval);
  const holeSize = firstMeaningfulText(bitSize, wellGeneral?.bitSize);
  if (!holeSize) return null;

  return {
    description: `${holeSize}" OPEN HOLE`,
    od: holeSize,
    shoe: firstText(wellGeneral?.md, wellGeneral?.depthDrilled),
    bit: holeSize,
  };
};
const prepareCasingOpenHoleRows = ({ casings, wellGeneral, intervals }) => {
  const rows = normalizeCasingRows(casings);
  const openHoleRow = buildOpenHoleRow({ wellGeneral, intervals });

  const hasOpenHole = rows.some((row) => {
    const label = firstText(row.type, row.description).toLowerCase();
    const size = firstText(row.bit, row.od, row.id);
    return label.includes("open hole") || (openHoleRow && size === openHoleRow.od);
  });

  if (openHoleRow && !hasOpenHole) {
    rows.unshift(openHoleRow);
  }

  return rows.slice(0, 8);
};
const calculatePumpDisplacement = (pump = {}) => {
  const linerId = toNumber(pump.linerId);
  const strokeLength = toNumber(pump.strokeLength);
  const efficiency = toNumber(pump.efficiency) / 100;
  const rodOd = toNumber(pump.rodOd);

  if (!linerId || !strokeLength || !efficiency) return 0;

  if (pump.type === "Duplex") {
    return rodOd > 0
      ? 0.000162 * (2 * linerId * linerId - rodOd * rodOd) * strokeLength * efficiency
      : 0.000324 * linerId * linerId * strokeLength * efficiency;
  }

  const constants = {
    Triplex: 0.000243,
    Quadplex: 0.000324,
    Quintuplex: 0.000405,
  };
  const constant = constants[pump.type] || 0;
  return constant ? constant * linerId * linerId * strokeLength * efficiency : 0;
};
const hasPumpData = (pump = {}) =>
  [
    pump.type,
    pump.model,
    pump.linerId,
    pump.rodOd,
    pump.strokeLength,
    pump.efficiency,
    pump.spm,
    pump.displacement,
    pump.rate,
    pump.maxPumpP,
    pump.maxHp,
    pump.surfaceLen,
    pump.surfaceId,
  ].some((value) => meaningfulText(value));
const normalizePumpRows = (pumps = []) => {
  const latestByRow = new Map();

  for (const pump of pumps.filter(hasPumpData)) {
    const rowNumber = Number(pump.rowNumber) || latestByRow.size + 1;
    const previous = latestByRow.get(rowNumber);
    const previousTime = new Date(previous?.updatedAt ?? previous?.createdAt ?? 0).getTime();
    const currentTime = new Date(pump?.updatedAt ?? pump?.createdAt ?? 0).getTime();
    if (!previous || currentTime >= previousTime) {
      latestByRow.set(rowNumber, { ...pump, rowNumber });
    }
  }

  return Array.from(latestByRow.values())
    .sort((left, right) => Number(left.rowNumber) - Number(right.rowNumber))
    .slice(0, 4);
};
const computeDrilledVolume = ({
  depthDrilled,
  lengthUnit,
  bitSize,
  diameterUnit,
  fluidVolumeUnit,
}) => {
  const depthFt = convertLength(depthDrilled, lengthUnit, "ft");
  const bitSizeIn = convertLength(bitSize, diameterUnit, "in");
  if (depthFt <= 0 || bitSizeIn <= 0) return 0;
  const volumeBbl =
    (depthFt * Math.PI * Math.pow(bitSizeIn / 12, 2)) / 4 / 5.614583333333333;
  return convertVolume(volumeBbl, "bbl", fluidVolumeUnit);
};
const calculatePipeVolume = ({ id, length }) => {
  const idIn = toNumber(id);
  const lengthFt = toNumber(length);
  if (idIn <= 0 || lengthFt <= 0) return 0;
  return (idIn * idIn * lengthFt) / 1029.4;
};
const calculateHoleVolume = (casing, mdInFeet) => {
  const id = toNumber(casing?.id || casing?.od || casing?.bit);
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

  return length > 0 ? calculatePipeVolume({ id, length }) : 0;
};
const isActiveSystemTarget = (value) =>
  text(value).toLowerCase() === "active system";
const activeReserveText = (active, reserve) =>
  `${round(active)}/${round(reserve)}`;
const buildReportFormat = (req) => ({
  lengthUnit: text(req.query.lengthUnit, "(ft)"),
  diameterUnit: text(req.query.diameterUnit, "(in)"),
  fluidVolumeUnit: text(req.query.fluidVolumeUnit, "(bbl)"),
  digits: clamp(toNumber(req.query.decimals, 2), 0, 4),
});
const clearCells = (ws, addresses) => addresses.forEach((a) => setCellValue(ws, a, ""));
const columnToNumber = (letters) =>
  letters.toUpperCase().split("").reduce((sum, ch) => sum * 26 + ch.charCodeAt(0) - 64, 0);
const fillRowRange = (ws, row, startColumn, endColumn, value = "") => {
  const start = columnToNumber(startColumn);
  const end = columnToNumber(endColumn);
  for (let col = start; col <= end; col += 1) ws.getRow(row).getCell(col).value = value ?? "";
};
const clearRange = (ws, startCell, endCell) => {
  const [, sc, sr] = startCell.match(/^([A-Z]+)(\d+)$/i) || [];
  const [, ec, er] = endCell.match(/^([A-Z]+)(\d+)$/i) || [];
  if (!sc || !sr || !ec || !er) return;
  for (let row = Number(sr); row <= Number(er); row += 1) {
    for (let col = columnToNumber(sc); col <= columnToNumber(ec); col += 1) {
      ws.getRow(row).getCell(col).value = "";
    }
  }
};
const clearRows = (ws, range, columns) => {
  for (let row = range.start; row <= range.end; row += 1) {
    for (const column of columns) setCellValue(ws, `${column}${row}`, "");
  }
};
const writeRows = (ws, range, columns, items, mapItem) => {
  clearRows(ws, range, columns);
  const maxRows = range.end - range.start + 1;
  items.slice(0, maxRows).forEach((item, index) => {
    Object.entries(mapItem(item)).forEach(([column, value]) => {
      setCellValue(ws, `${column}${range.start + index}`, value);
    });
  });
};

const clearDmrDynamicAreas = (ws) => {
  [
    ["AC7", "AC7"], ["AT7", "AT7"], ["BL7", "BL7"], ["H8", "H11"], ["T8", "T8"],
    ["AB8", "AB11"], ["AT8", "AT11"], ["BL8", "BL11"], ["H14", "P21"], ["Q14", "V21"],
    ["W14", "AB21"], ["AC14", "AI21"], ["AJ14", "AR21"], ["AS14", "AX21"], ["AY14", "BD21"],
    ["BE14", "BK21"], ["BL14", "BS21"], ["M23", "BS34"], ["P36", "AI80"],
    ["AJ36", "BS51"], ["AJ53", "BS86"], ["L92", "Q96"], ["AC92", "AI94"],
    ["AT93", "AY94"], ["BM93", "BS94"], ["AC96", "AI98"], ["AR96", "AX97"],
    ["BF97", "BS99"],
    ["L100", "AI105"], ["AR99", "AX101"], ["BF105", "BS108"], ["AT108", "AX111"],
  ].forEach(([start, end]) => clearRange(ws, start, end));
};

const clearInventoryDynamicAreas = (ws) => {
  [
    "V2","L7","U7","AC7","D8","L8","U8","AC8","D9","L9","U9","AC9",
    "D10","L10","U10","AC10","D11","L11","U11","AC11",
  ].forEach((address) => setCellValue(ws, address, ""));
  clearCells(ws, SUMMARY_VALUE_CELLS);
  clearCells(ws, COST_SUMMARY_VALUE_CELLS);
  clearCells(ws, CUTTINGS_ANALYSIS_VALUE_CELLS);
};

const computeVolumeSummary = ({
  activePits = [],
  reservePits = [],
  drillStrings = [],
  casings = [],
  wellGeneral,
  productsUsed = [],
  addWaterRows = [],
  receiveMudRows = [],
  transferRows = [],
  returnLostRows = [],
  otherVolRows = [],
  mudLossRows = [],
  mudLossStorageRows = [],
  emptyFluidRows = [],
}) => {
  const currentActiveVolume = sumBy(activePits, (pit) => getActivePitVolume(pit));
  const reserveVolume = sumBy(reservePits, (pit) => getPitVolume(pit));
  const activeWaterAddition = sumBy(
    addWaterRows.filter((item) => isActiveSystemTarget(item.to)),
    (item) => item.volume
  );
  const reserveWaterAddition = sumBy(
    addWaterRows.filter((item) => !isActiveSystemTarget(item.to)),
    (item) => item.volume
  );
  const activeReceived = sumBy(
    receiveMudRows.filter((item) => isActiveSystemTarget(item.to)),
    (item) => item.netVolume || item.volume
  );
  const reserveReceived = sumBy(
    receiveMudRows.filter((item) => !isActiveSystemTarget(item.to)),
    (item) => item.netVolume || item.volume
  );
  const totalWaterAddition = sumBy(addWaterRows, (item) => item.volume);
  const totalReceived = sumBy(receiveMudRows, (item) => item.netVolume || item.volume);
  const totalProductAddition = sumBy(productsUsed, (item) => item.volumeBbl);
  const totalOtherAddition = sumBy(otherVolRows, (item) => item.totalVolume);
  const volumeNotFluid = sumBy(otherVolRows, (item) => item.volumeNotFluid);
  const totalTransferOut = sumBy(transferRows, (item) => item.totalTransferVol);
  const totalReturned = sumBy(returnLostRows, (item) => item.volReturned);
  const totalReturnLost = sumBy(returnLostRows, (item) => item.volLost);
  const emptyDumpLoss = sumBy(
    emptyFluidRows.filter((item) => text(item.actionType).toLowerCase() === "dump"),
    (item) => item.volume || item.totalVolume
  );
  const emptyTransferOut = sumBy(
    emptyFluidRows.filter((item) => text(item.actionType).toLowerCase() === "transfer to storage"),
    (item) => item.volume || item.totalVolume
  );
  const activeMudLoss = sumBy(mudLossRows, (item) => item.totalLoss);
  const reserveMudLoss = sumBy(mudLossStorageRows, (item) => item.totalLoss);
  const totalLoss = activeMudLoss + reserveMudLoss + totalReturnLost + emptyDumpLoss;
  const totalAdditions =
    totalWaterAddition + totalReceived + totalProductAddition + totalOtherAddition;
  const totalTransfersOut = totalTransferOut + totalReturned + emptyTransferOut;
  const estimatedStartingVolume = Math.max(
    0,
    currentActiveVolume - totalAdditions + totalTransfersOut + totalLoss
  );
  const drillstringVolume = sumBy(drillStrings, (item) =>
    calculatePipeVolume({ id: item.id, length: item.length })
  );
  const casingForHole = [...casings]
    .reverse()
    .find((item) => toNumber(item.id || item.od || item.bit) > 0);
  const downholeVolume = calculateHoleVolume(
    casingForHole,
    firstMeaningfulText(wellGeneral?.md, wellGeneral?.depthDrilled)
  );
  const annularVolume = Math.max(0, downholeVolume - drillstringVolume);
  const lossBreakdown = {
    shakersHydroclones: sumBy(mudLossRows, (item) => item.shakers),
    cuttingsRetention: sumBy(mudLossRows, (item) => item.cuttingsRetention),
    centrifuge: sumBy(mudLossRows, (item) => item.centrifuge),
    evaporation:
      sumBy(mudLossRows, (item) => item.evaporation) +
      sumBy(mudLossStorageRows, (item) => item.evaporation),
    dumped:
      sumBy(mudLossRows, (item) => item.dump) +
      sumBy(mudLossStorageRows, (item) => item.dump) +
      emptyDumpLoss,
    formation: sumBy(mudLossRows, (item) => item.formation),
    pitCleaning:
      sumBy(mudLossRows, (item) => item.pitCleaning) +
      sumBy(mudLossStorageRows, (item) => item.pitCleaning),
    tripping: sumBy(mudLossRows, (item) => item.tripping),
    others:
      sumBy(mudLossRows, (item) =>
        toNumber(item.seepage) +
        toNumber(item.abandonInHole) +
        toNumber(item.leftBehindCasing) +
        toNumber(item.extraLossVolume)
      ) + totalReturnLost,
  };
  const activeBuilt = activeWaterAddition + activeReceived + totalProductAddition + totalOtherAddition;
  const reserveBuilt = reserveWaterAddition + reserveReceived;
  const returnedActive = sumBy(
    returnLostRows.filter((item) => isActiveSystemTarget(item.from)),
    (item) => item.volReturned
  );
  const returnedReserve = sumBy(
    returnLostRows.filter((item) => !isActiveSystemTarget(item.from)),
    (item) => item.volReturned
  );

  return {
    startingVolume: round(estimatedStartingVolume),
    receivedFromReserve: round(totalReceived),
    productAddition: round(totalProductAddition),
    weightMaterialAddition: 0,
    baseOilAddition: 0,
    waterAddition: round(totalWaterAddition),
    wholeFluidAddition: round(totalOtherAddition),
    totalAdditions: round(totalAdditions),
    transferToReserve: round(totalTransferOut),
    returnToWarehouse: round(totalReturned),
    totalTransfersOut: round(totalTransfersOut),
    totalLoss: round(totalLoss),
    reserveVolume: round(reserveVolume),
    annularVolume: round(annularVolume),
    drillstringVolume: round(drillstringVolume),
    downholeVolume: round(downholeVolume),
    totalCircVolume: round(currentActiveVolume + downholeVolume),
    volumeBelowBit: 0,
    dailyVolBuilt: activeReserveText(activeBuilt, reserveBuilt),
    dailyVolLost: activeReserveText(activeMudLoss + totalReturnLost + emptyDumpLoss, reserveMudLoss),
    dailyVolReturned: activeReserveText(returnedActive, returnedReserve),
    volumeNotFluid: round(volumeNotFluid),
    totalRigsiteVolume: round(currentActiveVolume + reserveVolume),
    lossBreakdown,
    finalActiveVolume: round(currentActiveVolume),
  };
};

const fillDmrHeader = (ws, { well, pad, report, wellGeneral, fluidName }) => {
  const reportNumber = text(report?.userReportNo || report?.reportNo || wellGeneral?.userReportNo || wellGeneral?.reportNo, "1");
  setCellValue(ws, "AC7", text(report?._id || well?._id || well?.apiWellNo));
  setCellValue(ws, "AT7", formatDate(report?.reportDate || wellGeneral?.date, getReportDate()));
  setCellValue(ws, "BB2", reportNumber);
  setCellValue(ws, "BL7", reportNumber);
  setCellValue(ws, "H8", displayText(well?.wellNameNo));
  setCellValue(ws, "T8", displayText(pad?.rig));
  setCellValue(ws, "AB8", displayText(pad?.fieldBlock));
  setCellValue(ws, "BL8", displayText(pad?.country || pad?.stateProvince));
  setCellValue(ws, "H9", displayText(pad?.operator));
  setCellValue(ws, "AB9", displayText(pad?.contractor));
  setCellValue(ws, "AT9", displayText(wellGeneral?.formation));
  setCellValue(ws, "BL9", displayText(wellGeneral?.md, "0"));
  setCellValue(ws, "H10", displayText(wellGeneral?.operatorRep || pad?.operatorRep));
  setCellValue(ws, "AB10", displayText(wellGeneral?.contractorRep || pad?.contractorRep));
  setCellValue(
    ws,
    "AT10",
    wellGeneral?.inc || wellGeneral?.azi
      ? `${toNumber(wellGeneral?.inc)}/${toNumber(wellGeneral?.azi)}`
      : "-"
  );
  setCellValue(ws, "BL10", displayText(wellGeneral?.tvd, "0"));
  setCellValue(ws, "H11", displayText(formatDate(well?.spudDate)));
  setCellValue(ws, "AB11", displayText(fluidName));
  setCellValue(ws, "AT11", displayText(wellGeneral?.activity));
  setCellValue(ws, "BL11", displayText(wellGeneral?.depthDrilled, "0"));
};

const normalizeMudKey = (value) =>
  text(value)
    .toLowerCase()
    .replace(/\*/g, "")
    .replace(/[()]/g, " ")
    .replace(/[._-]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
const mudTableEntries = (mudReportState = {}) =>
  Object.entries(
    mudReportState?.propertyTable && typeof mudReportState.propertyTable === "object"
      ? mudReportState.propertyTable
      : {}
  );
const findMudRow = (mudReportState, ...tests) => {
  for (const [key, value] of mudTableEntries(mudReportState)) {
    const normalized = normalizeMudKey(key);
    if (tests.some((test) => test(normalized))) {
      return Array.isArray(value) ? value.map((item) => text(item)) : [];
    }
  }
  return [];
};
const mudValueAt = (row, index) => text(row?.[index]);
const mudPlanValue = (row) => {
  const low = mudValueAt(row, 3);
  const high = mudValueAt(row, 4);
  if (low && high && low !== high) return `${low} - ${high}`;
  return low || high;
};
const buildMudGroups = (row, fallbacks = []) => [
  mudValueAt(row, 0) || text(fallbacks[0]),
  mudValueAt(row, 1) || text(fallbacks[1]),
  mudValueAt(row, 2) || text(fallbacks[2]),
  mudPlanValue(row) || text(fallbacks[3]),
];
const combineMudRows = (left, right, index) => {
  const leftValue = mudValueAt(left, index);
  const rightValue = mudValueAt(right, index);
  if (leftValue && rightValue) return `${leftValue}/${rightValue}`;
  return leftValue || rightValue;
};
const buildMudRatioGroups = (direct, left, right) => {
  if (direct.some((value) => text(value))) return buildMudGroups(direct);
  const planLeft = mudPlanValue(left);
  const planRight = mudPlanValue(right);
  return [
    combineMudRows(left, right, 0),
    combineMudRows(left, right, 1),
    combineMudRows(left, right, 2),
    planLeft && planRight ? `${planLeft}/${planRight}` : planLeft || planRight,
  ];
};
const fillMudPropertyRows = (ws, { mudReportState, activePits, fluidName, wellGeneral }) => {
  const savedFluidName = firstText(mudReportState?.fluidName, fluidName);
  const description = findMudRow(mudReportState, (key) => key === "description");
  const sampleFrom = findMudRow(mudReportState, (key) => key === "sample from");
  const timeSample = findMudRow(mudReportState, (key) => key.includes("time sample"));
  const flowlineTemp = findMudRow(
    mudReportState,
    (key) => key.includes("flowline"),
    (key) => key.includes("suction")
  );
  const depth = findMudRow(
    mudReportState,
    (key) => key === "depth",
    (key) => key === "md",
    (key) => key.includes("measured depth")
  );
  const mw = findMudRow(
    mudReportState,
    (key) => key === "mw" || key.startsWith("mw ") || key.includes("mud weight")
  );
  const funnel = findMudRow(mudReportState, (key) => key.includes("funnel"));
  const tempForPv = findMudRow(
    mudReportState,
    (key) => key.includes("t for pv"),
    (key) => key.includes("temp") && key.includes("pv")
  );
  const pv = findMudRow(
    mudReportState,
    (key) => (key === "pv" || key.startsWith("pv ")) && !key.includes("for")
  );
  const yp = findMudRow(mudReportState, (key) => key === "yp" || key.startsWith("yp "));
  const r600r300 = findMudRow(
    mudReportState,
    (key) => key.includes("r600") && key.includes("r300")
  );
  const r200r100 = findMudRow(
    mudReportState,
    (key) => key.includes("r200") && key.includes("r100")
  );
  const r6r3 = findMudRow(mudReportState, (key) => key.includes("r6") && key.includes("r3"));
  const r600 = findMudRow(mudReportState, (key) => key === "r600" || key.startsWith("r600 "));
  const r300 = findMudRow(mudReportState, (key) => key === "r300" || key.startsWith("r300 "));
  const r200 = findMudRow(mudReportState, (key) => key === "r200" || key.startsWith("r200 "));
  const r100 = findMudRow(mudReportState, (key) => key === "r100" || key.startsWith("r100 "));
  const r6 = findMudRow(mudReportState, (key) => key === "r6" || key.startsWith("r6 "));
  const r3 = findMudRow(mudReportState, (key) => key === "r3" || key.startsWith("r3 "));
  const gel = findMudRow(
    mudReportState,
    (key) => key.includes("gel") && (key.includes("10") || key.includes("sec"))
  );
  const apiFiltrate = findMudRow(
    mudReportState,
    (key) => key.includes("api filtrate") && !key.includes("cake")
  );
  const apiCake = findMudRow(
    mudReportState,
    (key) => key.includes("api") && key.includes("cake")
  );
  const hthpTemp = findMudRow(
    mudReportState,
    (key) => key.includes("t for hthp"),
    (key) => key.includes("temp") && key.includes("hthp")
  );
  const hthpFiltrate = findMudRow(
    mudReportState,
    (key) => key.includes("hthp") && key.includes("filtrate") && !key.includes("cake")
  );
  const hthpCake = findMudRow(
    mudReportState,
    (key) => key.includes("hthp") && key.includes("cake")
  );
  const solids = findMudRow(
    mudReportState,
    (key) =>
      (key === "solids" || key.startsWith("solids ") || key === "retort solids") &&
      !key.includes("correct") &&
      !key.includes("corr") &&
      !key.includes("drill") &&
      !key.includes("salt")
  );
  const oil = findMudRow(
    mudReportState,
    (key) => (key === "oil" || key.startsWith("oil ")) && !key.includes("ratio")
  );
  const water = findMudRow(
    mudReportState,
    (key) => (key === "water" || key.startsWith("water ")) && !key.includes("phase")
  );
  const sand = findMudRow(mudReportState, (key) => key.includes("sand content"));
  const mbt = findMudRow(
    mudReportState,
    (key) => key.includes("mbt") || key.includes("methylene")
  );
  const ph = findMudRow(mudReportState, (key) => key === "ph" || key.startsWith("ph "));
  const mudAlkalinity = findMudRow(
    mudReportState,
    (key) => key.includes("mud alkalinity") || key.includes("whole mud alkalinity")
  );
  const filtratePf = findMudRow(
    mudReportState,
    (key) => key.includes("filtrate alkalinity") && key.includes("pf")
  );
  const filtrateMf = findMudRow(
    mudReportState,
    (key) => key.includes("filtrate alkalinity") && key.includes("mf")
  );
  const calcium = findMudRow(
    mudReportState,
    (key) => key === "calcium" || key.startsWith("calcium ")
  );
  const chlorides = findMudRow(
    mudReportState,
    (key) =>
      key.includes("chloride") &&
      !key.includes("cacl2") &&
      !key.includes("calcium chloride")
  );
  const totalHardness = findMudRow(mudReportState, (key) => key.includes("total hardness"));
  const excessLime = findMudRow(mudReportState, (key) => key.includes("excess lime"));
  const potassium = findMudRow(
    mudReportState,
    (key) => key === "k+" || key === "k" || key.startsWith("kcl")
  );
  const makeUpWaterChlorides = findMudRow(
    mudReportState,
    (key) => key.includes("make up") && key.includes("chloride")
  );
  const solidsAdjusted = findMudRow(
    mudReportState,
    (key) => key.includes("solids adjusted") || key.includes("corrected solids")
  );
  const fineLcm = findMudRow(mudReportState, (key) => key.includes("fine lcm"));

  const activeDensity = firstMeaningfulText(activePits[0]?.density, activePits[1]?.density);
  const rowValues = {
    36: buildMudGroups(description, [savedFluidName, savedFluidName, savedFluidName, savedFluidName]),
    37: buildMudGroups(sampleFrom, [activePits[0]?.pitName, activePits[1]?.pitName]),
    38: buildMudGroups(timeSample, [wellGeneral?.time, wellGeneral?.time]),
    39: buildMudGroups(flowlineTemp, [wellGeneral?.suctionT, wellGeneral?.suctionT]),
    40: buildMudGroups(depth, [wellGeneral?.md, wellGeneral?.md]),
    41: buildMudGroups(mw, [activeDensity, activeDensity]),
    42: buildMudGroups(funnel),
    43: buildMudGroups(tempForPv),
    44: buildMudGroups(pv),
    45: buildMudGroups(yp),
    46: buildMudRatioGroups(r600r300, r600, r300),
    47: buildMudRatioGroups(r200r100, r200, r100),
    48: buildMudRatioGroups(r6r3, r6, r3),
    49: buildMudGroups(gel),
    50: buildMudGroups(apiFiltrate),
    51: buildMudGroups(apiCake),
    52: buildMudGroups(hthpTemp),
    53: buildMudGroups(hthpFiltrate),
    54: buildMudGroups(hthpCake),
    55: buildMudGroups(solids),
    56: buildMudGroups(oil),
    57: buildMudGroups(water),
    58: buildMudGroups(sand),
    59: buildMudGroups(mbt),
    60: buildMudGroups(ph),
    61: buildMudGroups(mudAlkalinity),
    62: buildMudGroups(filtratePf),
    63: buildMudGroups(filtrateMf),
    64: buildMudGroups(calcium),
    65: buildMudGroups(chlorides),
    66: buildMudGroups(totalHardness),
    67: buildMudGroups(excessLime),
    68: buildMudGroups(potassium),
    69: buildMudGroups(makeUpWaterChlorides),
    70: buildMudGroups(solidsAdjusted),
    71: buildMudGroups(fineLcm),
  };

  const columns = [["P", "T"], ["U", "Y"], ["Z", "AD"], ["AE", "AI"]];
  Object.entries(rowValues).forEach(([row, values]) => {
    columns.forEach(([start, end], index) => {
      fillRowRange(ws, Number(row), start, end, values[index] ?? "");
    });
  });
};

const normalizeSolidsAnalysisRows = (rows = []) => {
  const latestBySample = new Map();
  for (const row of rows) {
    const sampleIndex = Number(row.sampleIndex) || 0;
    const previous = latestBySample.get(sampleIndex);
    const previousTime = new Date(previous?.updatedAt ?? previous?.createdAt ?? 0).getTime();
    const currentTime = new Date(row?.updatedAt ?? row?.createdAt ?? 0).getTime();
    if (!previous || currentTime >= previousTime) {
      latestBySample.set(sampleIndex, row);
    }
  }
  return [0, 1, 2].map((sampleIndex) => latestBySample.get(sampleIndex) || null);
};

const fillDmrSolidsAnalysisRows = (ws, solidsAnalysisRows = []) => {
  const samples = normalizeSolidsAnalysisRows(solidsAnalysisRows);
  const columns = [["P", "T"], ["U", "Y"], ["Z", "AD"]];
  const rowMap = {
    70: "correctedSolids",
    73: "brineSG",
    74: "dissolvedSolids",
    75: "correctedSolids",
    76: "lgsPercent",
    77: "lgsLb",
    78: "hgsPercent",
    79: "hgsLb",
    80: "avgSG",
  };

  Object.entries(rowMap).forEach(([row, key]) => {
    columns.forEach(([start, end], index) => {
      const value = roundOrBlank(samples[index]?.[key], key === "brineSG" ? 4 : 2);
      fillRowRange(ws, Number(row), start, end, value);
    });
  });
};

const normalizeSceKey = (value) => text(value).toLowerCase().replace(/\s+/g, " ").trim();
const sceHasText = (row = {}, fields = []) =>
  fields.some((field) => text(row?.[field]));
const shakerSortValue = (row = {}) => {
  const number = Number(text(row.shaker).match(/\d+/)?.[0]);
  return Number.isFinite(number) ? number : 999;
};
const shakerScreenInfo = (row = {}) => {
  const screens = [
    row.screen1,
    row.screen2,
    row.screen3,
    row.screen4,
    row.screen5,
    row.screen6,
    row.screen7,
    row.screen8,
  ].map((value) => text(value)).filter(Boolean);
  return firstText(screens.join("/"), row.screens, row.model);
};
const otherSceModelInfo = (row = {}) =>
  [row.model1, row.model2, row.model3].map((value) => text(value)).filter(Boolean).join("/");
const fillDmrSceRows = (ws, { shakers = [], otherSceRows = [] }) => {
  const shakerRows = [...shakers]
    .filter((row) =>
      sceHasText(row, [
        "model",
        "screens",
        "screen1",
        "screen2",
        "screen3",
        "screen4",
        "screen5",
        "screen6",
        "screen7",
        "screen8",
        "time",
      ])
    )
    .sort((left, right) => shakerSortValue(left) - shakerSortValue(right))
    .slice(0, 3);

  [97, 98, 99].forEach((row, index) => {
    const item = shakerRows[index];
    fillRowRange(ws, row, "AY", "BE", "Shaker");
    fillRowRange(ws, row, "BF", "BO", item ? shakerScreenInfo(item) : "");
    fillRowRange(ws, row, "BP", "BS", item ? roundOrBlank(item.time, 2) : "");
  });

  const availableOtherRows = otherSceRows.filter((row) =>
    sceHasText(row, ["model1", "model2", "model3", "uf", "of", "time"])
  );
  const byType = new Map(
    availableOtherRows.map((row) => [normalizeSceKey(row.type), row])
  );

  [
    [105, "Degasser"],
    [106, "Desander"],
    [107, "Desilter"],
    [108, "Centrifuge"],
  ].forEach(([row, label]) => {
    const key = normalizeSceKey(label);
    const item =
      byType.get(key) ||
      availableOtherRows.find((candidate) => normalizeSceKey(candidate.type).includes(key));
    fillRowRange(ws, row, "AY", "BE", firstText(item?.type, label));
    fillRowRange(ws, row, "BF", "BJ", item ? firstText(item.uf, otherSceModelInfo(item)) : "");
    fillRowRange(ws, row, "BK", "BO", item ? text(item.of) : "");
    fillRowRange(ws, row, "BP", "BS", item ? roundOrBlank(item.time, 2) : "");
  });
};

const fillDmrTopSections = (ws, { drillStrings, casings, summary, activePits, fluidName, wellGeneral, consumeProducts, mudReportState, solidsAnalysisRows }) => {
  for (let index = 0; index < 8; index += 1) {
    const row = 14 + index;
    const drill = drillStrings[index];
    const casing = casings[index];
    setCellValue(ws, `H${row}`, text(drill?.description));
    setCellValue(ws, `Q${row}`, drill ? round(drill.od, 3) : "");
    setCellValue(ws, `W${row}`, drill ? round(drill.id, 3) : "");
    setCellValue(ws, `AC${row}`, drill ? round(drill.length, 2) : "");
    const casingLabel = firstText(
      casing?.type,
      casing?.description,
      meaningfulText(casing?.id) ? `${meaningfulText(casing.id)}" OPEN HOLE` : ""
    );
    const casingOd = firstMeaningfulText(casing?.od, casing?.id, casing?.bit);
    const casingShoe = firstMeaningfulText(casing?.shoe, casing?.top);
    const bitValue = firstMeaningfulText(casing?.bit, casing?.id, casing?.od);
    setCellValue(ws, `AJ${row}`, casingLabel);
    setCellValue(ws, `AS${row}`, roundOrBlank(casingOd, 3));
    setCellValue(ws, `AY${row}`, roundOrBlank(casingShoe, 2));
    setCellValue(ws, `BE${row}`, bitValue);
    setCellValue(ws, `BL${row}`, text(casing?.toc));
  }

  [
    ["M24", summary.startingVolume], ["N24", summary.startingVolume], ["O24", summary.startingVolume],
    ["P24", summary.startingVolume], ["Q24", summary.startingVolume], ["R24", summary.startingVolume],
    ["M25", summary.receivedFromReserve], ["N25", summary.receivedFromReserve], ["O25", summary.receivedFromReserve],
    ["P25", summary.receivedFromReserve], ["Q25", summary.receivedFromReserve], ["R25", summary.receivedFromReserve],
    ["M26", summary.productAddition], ["N26", summary.productAddition], ["O26", summary.productAddition],
    ["P26", summary.productAddition], ["Q26", summary.productAddition], ["R26", summary.productAddition],
    ["M29", summary.waterAddition], ["N29", summary.waterAddition], ["O29", summary.waterAddition],
    ["P29", summary.waterAddition], ["Q29", summary.waterAddition], ["R29", summary.waterAddition],
    ["M30", summary.wholeFluidAddition], ["N30", summary.wholeFluidAddition], ["O30", summary.wholeFluidAddition],
    ["P30", summary.wholeFluidAddition], ["Q30", summary.wholeFluidAddition], ["R30", summary.wholeFluidAddition],
    ["M31", summary.totalAdditions], ["N31", summary.totalAdditions], ["O31", summary.totalAdditions],
    ["P31", summary.totalAdditions], ["Q31", summary.totalAdditions], ["R31", summary.totalAdditions],
    ["M32", summary.transferToReserve], ["N32", summary.transferToReserve], ["O32", summary.transferToReserve],
    ["P32", summary.transferToReserve], ["Q32", summary.transferToReserve], ["R32", summary.transferToReserve],
    ["M33", summary.returnToWarehouse], ["N33", summary.returnToWarehouse], ["O33", summary.returnToWarehouse],
    ["P33", summary.returnToWarehouse], ["Q33", summary.returnToWarehouse], ["R33", summary.returnToWarehouse],
    ["M34", summary.totalTransfersOut], ["N34", summary.totalTransfersOut], ["O34", summary.totalTransfersOut],
    ["P34", summary.totalTransfersOut], ["Q34", summary.totalTransfersOut], ["R34", summary.totalTransfersOut],
    ["AU23", summary.finalActiveVolume], ["AV23", summary.finalActiveVolume], ["AW23", summary.finalActiveVolume],
    ["AX23", summary.finalActiveVolume], ["AY23", summary.finalActiveVolume], ["AU34", summary.finalActiveVolume],
    ["AV34", summary.finalActiveVolume], ["AW34", summary.finalActiveVolume], ["AX34", summary.finalActiveVolume],
    ["AY34", summary.finalActiveVolume],
  ].forEach(([address, value]) => setCellValue(ws, address, value));

  [
    ["M23", "Daily"], ["P23", "Cum. Int."], ["AB23", "Daily"], ["AF23", "Cum. Int."],
  ].forEach(([address, value]) => setCellValue(ws, address, value));

  [
    [24, summary.startingVolume],
    [25, summary.receivedFromReserve],
    [26, summary.productAddition],
    [27, summary.weightMaterialAddition],
    [28, summary.baseOilAddition],
    [29, summary.waterAddition],
    [30, summary.wholeFluidAddition],
    [31, summary.totalAdditions],
    [32, summary.transferToReserve],
    [33, summary.returnToWarehouse],
    [34, summary.totalTransfersOut],
  ].forEach(([row, value]) => {
    fillRowRange(ws, row, "M", "R", value);
  });

  [
    [24, "Shakers/Hydroclones", summary.lossBreakdown?.shakersHydroclones],
    [25, "Cuttings Retention", summary.lossBreakdown?.cuttingsRetention],
    [26, "Centrifuge", summary.lossBreakdown?.centrifuge],
    [27, "Evaporation", summary.lossBreakdown?.evaporation],
    [28, "Dumped", summary.lossBreakdown?.dumped],
    [29, "Formation", summary.lossBreakdown?.formation],
    [30, "Pit Cleaning", summary.lossBreakdown?.pitCleaning],
    [31, "Tripping", summary.lossBreakdown?.tripping],
    [32, "Others", summary.lossBreakdown?.others],
    [33, "Total Losses", summary.totalLoss],
    [34, "Final Active Volume", summary.finalActiveVolume],
  ].forEach(([row, label, value]) => {
    fillRowRange(ws, row, "S", "AA", label);
    fillRowRange(ws, row, "AB", "AE", round(value));
    fillRowRange(ws, row, "AF", "AI", row === 34 ? "" : round(value));
  });

  [
    [23, "Active Pit Vol", summary.finalActiveVolume],
    [24, "Annular Volume", summary.annularVolume],
    [25, "Drillstring Volume", summary.drillstringVolume],
    [26, "Downhole Vol", summary.downholeVolume],
    [27, "Total Circ. Vol", summary.totalCircVolume],
    [28, "Vol Below Bit", summary.volumeBelowBit],
    [29, "Reserve Vol", summary.reserveVolume],
    [30, "Daily Vol Built (Active/Reserve)", summary.dailyVolBuilt],
    [31, "Daily Vol Lost (Active/Reserve)", summary.dailyVolLost],
    [32, "Daily Vol Returned (Active/Reserve)", summary.dailyVolReturned],
    [33, "Volume Not Fluid", summary.volumeNotFluid],
    [34, "Total Fluid Volume at Rigsite", summary.totalRigsiteVolume],
  ].forEach(([row, label, value]) => {
    fillRowRange(ws, row, "AJ", "AT", label);
    fillRowRange(ws, row, "AU", "AY", value);
  });

  for (let index = 0; index < 12; index += 1) {
    const row = 23 + index;
    const pit = activePits[index];
    setCellValue(ws, `BA${row}`, text(pit?.pitName));
    setCellValue(ws, `BN${row}`, pit ? round(getActivePitVolume(pit)) : "");
  }

  fillMudPropertyRows(ws, { mudReportState, activePits, fluidName, wellGeneral });
  fillDmrSolidsAnalysisRows(ws, solidsAnalysisRows);

  for (let index = 0; index < 16; index += 1) {
    const row = 37 + index;
    const item = consumeProducts[index];
    setCellValue(ws, `AJ${row}`, text(item?.product));
    setCellValue(ws, `AT${row}`, text(item?.unit));
    setCellValue(ws, `AY${row}`, item ? round(item.used) : "");
    setCellValue(ws, `BC${row}`, item ? round(item.used) : "");
    setCellValue(ws, `BH${row}`, item ? round(item.price, 3) : "");
    setCellValue(ws, `BN${row}`, item ? round(item.cost || item.price * item.used, 3) : "");
  }
};

const fillDmrBottomSections = (ws, {
  report,
  wellGeneral,
  pad,
  well,
  summary,
  pumps,
  productDailyCost,
  engineeringDailyCost,
  cuttingsAnalysis,
  reportFormat,
  shakers,
  otherSceRows,
}) => {
  const generatedOperationalComments = [
    text(report?.notes),
    text(wellGeneral?.activity) ? `Activity: ${wellGeneral.activity}` : "",
    text(wellGeneral?.formation) ? `Formation: ${wellGeneral.formation}` : "",
    wellGeneral?.md ? `Measured Depth: ${round(wellGeneral.md)} ft` : "",
    wellGeneral?.depthDrilled ? `Depth drilled last 24 hrs: ${round(wellGeneral.depthDrilled)} ft` : "",
    well?.wellNameNo ? `Well: ${well.wellNameNo}` : "",
    pad?.fieldBlock ? `Field/Block: ${pad.fieldBlock}` : "",
    summary?.finalActiveVolume ? `Final active volume: ${summary.finalActiveVolume} bbl` : "",
  ].filter(Boolean).join("\n");

  const recommendedTreatment = firstText(
    report?.recommendedTreatment,
    report?.notes
  );
  const operationalComments = [
    text(report?.remarks),
    text(report?.recapRemarks)
      ? `Recap Remarks:\n${text(report.recapRemarks)}`
      : "",
  ].filter(Boolean).join("\n\n");

  setCellValue(
    ws,
    "AJ53",
    recommendedTreatment ||
      "No recommended tour treatments were saved for this report."
  );
  setCellValue(
    ws,
    "AJ73",
    operationalComments ||
      generatedOperationalComments ||
      "No operational comments were saved for this report."
  );

  pumps.slice(0, 4).forEach((pump, index) => {
    const startColumn = ["L", "R", "X", "AD"][index];
    const baseColumn = columnToNumber(startColumn);
    const displacement = firstMeaningfulText(
      pump.displacement,
      calculatePumpDisplacement(pump)
    );
    ws.getRow(100).getCell(baseColumn).value = index + 1;
    ws.getRow(101).getCell(baseColumn).value = roundOrBlank(pump.linerId, 3);
    ws.getRow(102).getCell(baseColumn).value = roundOrBlank(pump.strokeLength, 3);
    ws.getRow(103).getCell(baseColumn).value = roundOrBlank(pump.efficiency, 2);
    ws.getRow(104).getCell(baseColumn).value = roundOrBlank(pump.spm, 2);
    ws.getRow(105).getCell(baseColumn).value = roundOrBlank(displacement, 4);
  });

  setCellValue(
    ws,
    "AJ104",
    `Depth Drilled Last 24 hrs (${unitSuffix(reportFormat.lengthUnit, "ft")})`
  );
  setCellValue(
    ws,
    "AJ105",
    `Vol. Drilled Last 24 hrs (${unitSuffix(reportFormat.fluidVolumeUnit, "bbl")})`
  );
  setCellValue(ws, "AT104", round(cuttingsAnalysis.depthDrilled, reportFormat.digits));
  setCellValue(ws, "AT105", round(cuttingsAnalysis.volumeDrilled, reportFormat.digits));

  if (wellGeneral?.depthDrilled) setCellValue(ws, "AE94", round(wellGeneral.depthDrilled, 2));
  if (wellGeneral?.wob) setCellValue(ws, "AT93", round(wellGeneral.wob, 2));
  if (wellGeneral?.onBottomTq) setCellValue(ws, "BM93", round(wellGeneral.onBottomTq, 2));
  if (wellGeneral?.offBottomTq) setCellValue(ws, "BM94", round(wellGeneral.offBottomTq, 2));
  fillDmrSceRows(ws, { shakers, otherSceRows });

  const totalDailyCost = round(productDailyCost + engineeringDailyCost, 3);
  const costValues = [
    round(productDailyCost, 3),
    round(productDailyCost, 3),
    round(engineeringDailyCost, 3),
    round(engineeringDailyCost, 3),
    round(productDailyCost, 3),
    round(engineeringDailyCost, 3),
    totalDailyCost,
    totalDailyCost,
  ];
  DMR_COST_VALUE_CELLS.forEach((address, index) => setCellValue(ws, address, costValues[index] ?? ""));
};

const fillInventoryHeader = (ws, { well, pad, report, wellGeneral }) => {
  setCellValue(ws, "I2", "Daily Inventory Report");
  setCellValue(ws, "V2", text(report?.userReportNo || report?.reportNo || wellGeneral?.reportNo, "1"));
  setCellValue(ws, "L7", text(well?._id || report?._id));
  setCellValue(ws, "U7", formatDate(report?.reportDate || wellGeneral?.date, getReportDate()));
  setCellValue(ws, "AC7", text(report?.userReportNo || report?.reportNo || wellGeneral?.reportNo, "1"));
  setCellValue(ws, "D8", displayText(well?.wellNameNo));
  setCellValue(ws, "L8", displayText(pad?.rig));
  setCellValue(ws, "U8", displayText(pad?.fieldBlock));
  setCellValue(ws, "AC8", displayText(pad?.stateProvince || pad?.country));
  setCellValue(ws, "D9", displayText(pad?.operator));
  setCellValue(ws, "L9", displayText(pad?.contractor));
  setCellValue(ws, "U9", displayText(wellGeneral?.formation));
  setCellValue(ws, "AC9", displayText(wellGeneral?.md, "0"));
  setCellValue(ws, "D10", displayText(wellGeneral?.operatorRep || pad?.operatorRep));
  setCellValue(ws, "L10", displayText(wellGeneral?.contractorRep || pad?.contractorRep));
  setCellValue(
    ws,
    "U10",
    wellGeneral?.inc || wellGeneral?.azi
      ? `${toNumber(wellGeneral?.inc)} / ${toNumber(wellGeneral?.azi)}`
      : "-"
  );
  setCellValue(ws, "AC10", displayText(wellGeneral?.tvd, "0"));
  setCellValue(ws, "D11", displayText(formatDate(well?.spudDate)));
  setCellValue(ws, "L11", "-");
  setCellValue(ws, "U11", displayText(wellGeneral?.activity));
  setCellValue(ws, "AC11", displayText(wellGeneral?.depthDrilled, "0"));
};

const hasServiceCostData = (item = {}, nameField) =>
  firstText(item[nameField], item.itemName) ||
  [
    item.code,
    item.unit,
    item.price,
    item.usage,
    item.used,
    item.cumulativeUsed,
    item.cost,
    item.costDollar,
    item.subtotal,
  ].some((value) => meaningfulText(value));

const normalizeServiceCostRows = (items = [], { category, nameField }) =>
  items
    .filter((item) => hasServiceCostData(item, nameField))
    .map((item) => {
      const usage = toNumber(item.usage ?? item.used ?? item.cumulativeUsed);
      const price = toNumber(item.price);
      const cost = toNumber(item.cost ?? item.costDollar ?? item.subtotal);
      const subtotal = cost || usage * price;

      return {
        category,
        itemName: firstText(item[nameField], item.itemName),
        code: text(item.code),
        unit: text(item.unit),
        price: round(price, 3),
        usage: round(usage, 3),
        used: round(usage, 3),
        cumulativeUsed: round(usage, 3),
        subtotal: round(subtotal, 3),
        costDollar: round(subtotal, 3),
      };
    });

const fillInventorySheet = (ws, {
  products,
  services,
  engineers,
  activePits,
  reservePits,
  activities,
  productDailyCost,
  engineeringDailyCost,
  summary,
  cuttingsAnalysis,
  reportFormat,
}) => {
  writeRows(ws, PRODUCT_ROWS, PRODUCT_COLUMNS, products, (item) => ({
    A: item.itemName || "",
    F: item.unit || "",
    I: round(item.price, 3),
    K: round(item.initial),
    M: round(item.rec),
    O: round(item.cumulativeRec),
    Q: round(item.ret),
    S: round(item.cumulativeRet),
    U: round(item.used),
    W: round(item.cumulativeUsed),
    Y: round(item.final),
    AA: round(item.costDollar, 3),
    AC: "",
    AE: "",
  }));

  clearCells(ws, SUMMARY_VALUE_CELLS);
  [["G67", summary.wholeFluidAddition],["J67", summary.wholeFluidAddition],["M67", summary.wholeFluidAddition],
   ["G69", summary.waterAddition],["J69", summary.waterAddition],["M69", summary.waterAddition],
   ["G70", summary.productAddition],["J70", summary.productAddition],["M70", summary.productAddition],
   ["G71", summary.weightMaterialAddition],["J71", summary.weightMaterialAddition],["M71", summary.weightMaterialAddition],
   ["G72", summary.transferToReserve],["J72", summary.transferToReserve],["M72", summary.transferToReserve],
   ["G73", summary.totalAdditions],["J73", summary.totalAdditions],["M73", summary.totalAdditions],
   ["X67", summary.transferToReserve],["AA67", summary.transferToReserve],["AD67", summary.transferToReserve],
   ["X68", summary.returnToWarehouse],["AA68", summary.returnToWarehouse],["AD68", summary.returnToWarehouse],
   ["X71", summary.totalLoss],["AA71", summary.totalLoss],["AD71", summary.totalLoss],
   ["X72", summary.finalActiveVolume],["AA72", summary.finalActiveVolume],["AD72", summary.finalActiveVolume],
   ["X73", summary.finalActiveVolume],["AA73", summary.finalActiveVolume],["AD73", summary.finalActiveVolume]].forEach(
    ([address, value]) => setCellValue(ws, address, value)
  );

  writeRows(ws, SERVICE_ROWS, SERVICE_COLUMNS, services, (item) => ({
    A: item.itemName || "",
    G: round(item.used ?? item.cumulativeUsed ?? item.usage),
    I: round(item.cumulativeUsed ?? item.used ?? item.usage),
    K: round(item.costDollar, 3),
  }));
  writeRows(ws, ACTIVE_PIT_ROWS, PIT_COLUMNS, activePits, (pit) => ({
    M: pit.pitName || "",
    S: round(getPitVolume(pit)),
    U: round(pit.density),
    W: pit.fluidType || "",
  }));
  writeRows(ws, TIME_ROWS, TIME_COLUMNS, activities, (activity) => ({
    AA: activity.description || "",
    AE: round(activity.hours),
  }));
  writeRows(ws, ENGINEERING_ROWS, SERVICE_COLUMNS, engineers, (item) => ({
    A: item.itemName || "",
    G: round(item.used ?? item.cumulativeUsed ?? item.usage),
    I: round(item.cumulativeUsed ?? item.used ?? item.usage),
    K: round(item.costDollar, 3),
  }));
  writeRows(ws, RESERVE_ROWS, PIT_COLUMNS, reservePits, (pit) => ({
    M: pit.pitName || "",
    S: round(pit.capacity),
    U: "",
    W: "",
  }));

  const totalDailyCost = round(productDailyCost + engineeringDailyCost, 3);
  clearCells(ws, COST_SUMMARY_VALUE_CELLS);
  [["G94", productDailyCost],["G95", productDailyCost],["G96", engineeringDailyCost],["G97", engineeringDailyCost],
   ["G98", productDailyCost],["G99", engineeringDailyCost],["G100", totalDailyCost],["G101", totalDailyCost]].forEach(
    ([address, value]) => setCellValue(ws, address, round(value, 3))
  );

  setCellValue(
    ws,
    "AA94",
    `Depth Drilled Last 24 hrs (${unitSuffix(reportFormat.lengthUnit, "ft")})`
  );
  setCellValue(
    ws,
    "AA95",
    `Vol. Drilled Last 24 hrs (${unitSuffix(reportFormat.fluidVolumeUnit, "bbl")})`
  );
  setCellValue(
    ws,
    "AA96",
    `Interval Cum. Cuttings (${unitSuffix(reportFormat.fluidVolumeUnit, "bbl")})`
  );
  setCellValue(
    ws,
    "AA97",
    `Well Cum. Cuttings (${unitSuffix(reportFormat.fluidVolumeUnit, "bbl")})`
  );
  setCellValue(ws, "AE94", round(cuttingsAnalysis.depthDrilled, reportFormat.digits));
  setCellValue(ws, "AE95", round(cuttingsAnalysis.volumeDrilled, reportFormat.digits));
  setCellValue(
    ws,
    "AE96",
    round(cuttingsAnalysis.intervalCumCuttings, reportFormat.digits)
  );
  setCellValue(ws, "AE97", round(cuttingsAnalysis.wellCumCuttings, reportFormat.digits));
};

const loadReportScopedList = async (
  Model,
  { wellId, reportId, sort = { createdAt: -1 }, limit }
) => {
  if (!wellId) return [];

  if (reportId) {
    const scoped = await Model.find({ wellId, reportId })
      .sort(sort)
      .limit(limit || 0)
      .lean();
    if (scoped.length > 0) return scoped;
  }

  return Model.find({ wellId, ...legacyReportScopeForModel(Model) })
    .sort(sort)
    .limit(limit || 0)
    .lean();
};

const loadExportDrillStrings = async ({ wellId, reportId }) => {
  if (!wellId) return [];

  if (reportId) {
    const scoped = await DrillString.find({ wellId, reportId })
      .sort({ createdAt: 1, _id: 1 })
      .limit(8)
      .lean();
    if (scoped.length > 0) return scoped;
  }

  const wellScopedLegacy = await DrillString.find({
    wellId,
    ...legacyReportScope(),
  })
    .sort({ createdAt: 1, _id: 1 })
    .limit(8)
    .lean();
  if (wellScopedLegacy.length > 0) return wellScopedLegacy;

  return DrillString.find({
    $and: [
      emptyFieldFilterForModel(DrillString, "wellId"),
      legacyReportScopeForModel(DrillString),
    ],
  })
    .sort({ createdAt: 1, _id: 1 })
    .limit(8)
    .lean();
};

const loadExportCasings = async ({ wellId, reportId }) => {
  if (!wellId) return [];

  const filter = reportId
    ? {
        wellId,
        $or: [
          { reportId },
          { reportId: { $exists: false } },
          { reportId: null },
          { reportId: "" },
        ],
      }
    : { wellId };

  return Casing.find(filter).sort({ createdAt: 1, _id: 1 }).lean();
};

const loadInventorySnapshot = async ({ wellId, reportId }) => {
  if (!wellId) return [];

  if (reportId) {
    const scoped = await InventorySnapshot.find({ wellId, reportId })
      .sort({ category: 1, itemName: 1 })
      .lean();
    if (scoped.length > 0) return scoped;
  }

  const legacy = await InventorySnapshot.find({
    wellId,
    ...legacyReportScopeWithEmpty(),
  })
    .sort({ category: 1, itemName: 1 })
    .lean();
  if (legacy.length > 0) return legacy;

  return InventorySnapshot.find({ wellId })
    .sort({ category: 1, itemName: 1 })
    .lean();
};

const loadExportPumps = async ({ wellId, reportId }) => {
  if (!wellId) return [];

  if (reportId) {
    const scoped = await Pump.find({ wellId, reportId })
      .sort({ rowNumber: 1, updatedAt: -1, createdAt: -1, _id: -1 })
      .lean();

    const normalizedScoped = normalizePumpRows(scoped);
    if (normalizedScoped.length > 0) {
      return normalizedScoped;
    }
  }

  const legacy = await Pump.find({ wellId, ...legacyReportScopeForModel(Pump) })
    .sort({ rowNumber: 1, updatedAt: -1, createdAt: -1, _id: -1 })
    .lean();
  const normalizedLegacy = normalizePumpRows(legacy);
  if (normalizedLegacy.length > 0) {
    return normalizedLegacy;
  }

  const latestForWell = await Pump.find({ wellId })
    .sort({ rowNumber: 1, updatedAt: -1, createdAt: -1, _id: -1 })
    .lean();
  return normalizePumpRows(latestForWell);
};

const loadExportWellGeneral = async ({ wellId, reportId, report }) => {
  if (!wellId) return null;

  if (reportId) {
    const byReportId = await WellGeneral.findOne({ wellId, reportId })
      .sort({ createdAt: -1, _id: -1 })
      .lean();
    if (byReportId) return byReportId;
  }

  const reportNo = text(report?.reportNo);
  if (reportNo) {
    const byReportNo = await WellGeneral.findOne({ wellId, reportNo })
      .sort({ createdAt: -1, _id: -1 })
      .lean();
    if (byReportNo) return byReportNo;
  }

  const legacy = await WellGeneral.findOne({
    wellId,
    ...legacyReportScopeWithEmpty(),
  })
    .sort({ createdAt: -1, _id: -1 })
    .lean();
  if (legacy) return legacy;

  return WellGeneral.findOne({ wellId })
    .sort({ createdAt: -1, _id: -1 })
    .lean();
};

const loadExportMudReportState = async ({ wellId, reportId }) => {
  if (!wellId) return null;

  if (reportId) {
    const scoped = await MudReportState.findOne({ wellId, reportId })
      .sort({ updatedAt: -1, _id: -1 })
      .lean();
    if (scoped) return scoped;
  }

  const legacy = await MudReportState.findOne({
    wellId,
    $or: [{ reportId: "" }, { reportId: null }, { reportId: { $exists: false } }],
  })
    .sort({ updatedAt: -1, _id: -1 })
    .lean();
  if (legacy) return legacy;

  return MudReportState.findOne({ wellId })
    .sort({ updatedAt: -1, _id: -1 })
    .lean();
};

const emptyWellScope = () => ({
  $or: [{ wellId: "" }, { wellId: null }, { wellId: { $exists: false } }],
});

const loadExportSolidsAnalysis = async ({ wellId, reportId }) => {
  if (!wellId && !reportId) return [];

  const queries = [];
  if (wellId && reportId) {
    queries.push({ wellId, reportId });
    queries.push({ reportId, ...emptyWellScope() });
  }
  if (wellId) {
    queries.push({ wellId, ...legacyReportScopeWithEmpty() });
    queries.push({ wellId });
  }
  if (reportId) {
    queries.push({ reportId });
  }

  for (const query of queries) {
    const rows = await SolidsAnalysis.find(query)
      .sort({ sampleIndex: 1, updatedAt: -1, createdAt: -1, _id: -1 })
      .lean();
    if (rows.length > 0) return rows;
  }
  return [];
};

export const exportInventoryReport = async (req, res) => {
  try {
    const { wellId } = req.params;
    const reportId = text(req.query.reportId);
    const reportFormat = buildReportFormat(req);
    if (!wellId) {
      return res.status(400).json({ success: false, message: "wellId is required" });
    }

    const report = reportId ? await Report.findById(reportId).lean().catch(() => null) : null;
    const [
      inventoryData, activities, well, drillStrings, casings, pumps, consumeProducts,
      liveServices, liveEngineering, addWaterRows, receiveMudRows, returnLostRows, transferRows, otherVolRows, mudLossRows, mudLossStorageRows,
      allOtherVolRows, intervals, mudReportState, solidsAnalysisRows, shakers, otherSceRows, emptyFluidRows,
    ] = await Promise.all([
      loadInventorySnapshot({ wellId, reportId }),
      loadReportScopedList(Activity, {
        wellId,
        reportId,
        sort: { createdAt: -1 },
        limit: 10,
      }),
      Well.findById(wellId).lean(),
      loadExportDrillStrings({ wellId, reportId }),
      loadExportCasings({ wellId, reportId }),
      loadExportPumps({ wellId, reportId }),
      loadReportScopedList(ConsumeProduct, { wellId, reportId }),
      loadReportScopedList(Service, { wellId, reportId, sort: { createdAt: 1, _id: 1 } }),
      loadReportScopedList(Engineering, { wellId, reportId, sort: { createdAt: 1, _id: 1 } }),
      loadReportScopedList(AddWater, { wellId, reportId }),
      loadReportScopedList(ReceiveMud, { wellId, reportId }),
      loadReportScopedList(ReturnLostMud, { wellId, reportId }),
      loadReportScopedList(TransferMud, { wellId, reportId }),
      loadReportScopedList(OtherVolAddition, { wellId, reportId }),
      loadReportScopedList(MudLoss, { wellId, reportId }),
      loadReportScopedList(MudLossStorage, { wellId, reportId }),
      OtherVolAddition.find({ wellId }).sort({ createdAt: 1, _id: 1 }).lean(),
      Interval.find({ wellId }).sort({ order: 1, createdAt: 1, _id: 1 }).lean(),
      loadExportMudReportState({ wellId, reportId }),
      loadExportSolidsAnalysis({ wellId, reportId }),
      loadReportScopedList(Shaker, { wellId, reportId, sort: { createdAt: 1, _id: 1 } }),
      loadReportScopedList(OtherSce, { wellId, reportId, sort: { createdAt: 1, _id: 1 } }),
      loadReportScopedList(EmptyFluidActiveSystem, { wellId, reportId }),
    ]);
    if (!well) {
      return res.status(404).json({ success: false, message: "Well not found" });
    }

    const [pad, wellGeneral, pits] = await Promise.all([
      well?.padId ? Pad.findById(well.padId).lean() : null,
      loadExportWellGeneral({ wellId, reportId, report }),
      reportId
        ? loadMergedPits({ wellId, reportId })
        : Pit.find({ wellId }).sort({ createdAt: 1, _id: 1 }).lean(),
    ]);

    const activePits = pits.filter((pit) => pit.initialActive === true);
    const reservePits = pits.filter((pit) => pit.initialActive === false);
    const fluidName =
      text(mudReportState?.fluidName) ||
      text(mudReportState?.fluidType) ||
      text(activePits[0]?.fluidType) ||
      text(report?.title) ||
      text(wellGeneral?.activity) ||
      "-";
    const timeDistributionRows =
      Array.isArray(wellGeneral?.timeDistributionRows) &&
      wellGeneral.timeDistributionRows.length > 0
        ? wellGeneral.timeDistributionRows
        : activities;
    const products = inventoryData.filter((item) => item.category === "Product");
    const snapshotServices = inventoryData.filter((item) => item.category === "Service");
    const snapshotEngineering = inventoryData.filter((item) => item.category === "Engineering");
    const serviceRows = normalizeServiceCostRows(liveServices, {
      category: "Service",
      nameField: "serviceName",
    });
    const engineeringRows = normalizeServiceCostRows(liveEngineering, {
      category: "Engineering",
      nameField: "engineeringName",
    });
    const services = serviceRows.length > 0 ? serviceRows : snapshotServices;
    const engineers = engineeringRows.length > 0 ? engineeringRows : snapshotEngineering;
    const summary = computeVolumeSummary({
      activePits,
      reservePits,
      drillStrings,
      casings,
      wellGeneral,
      productsUsed: consumeProducts,
      addWaterRows,
      receiveMudRows,
      transferRows,
      returnLostRows,
      otherVolRows,
      mudLossRows,
      mudLossStorageRows,
      emptyFluidRows,
    });
    const productDailyCost = sumBy(products, (item) => item.costDollar);
    const engineeringDailyCost = sumBy(engineers, (item) => item.costDollar);
    const intervalBitSize = resolveIntervalBitSize(intervals, wellGeneral?.interval);
    const casingOpenHoleRows = prepareCasingOpenHoleRows({
      casings,
      wellGeneral,
      intervals,
    });
    const cuttingsAnalysis = {
      depthDrilled: toNumber(wellGeneral?.depthDrilled),
      volumeDrilled: computeDrilledVolume({
        depthDrilled: wellGeneral?.depthDrilled,
        lengthUnit: reportFormat.lengthUnit,
        bitSize: intervalBitSize,
        diameterUnit: reportFormat.diameterUnit,
        fluidVolumeUnit: reportFormat.fluidVolumeUnit,
      }),
      intervalCumCuttings: sumBy(otherVolRows, (item) => item.cuttings),
      wellCumCuttings: sumBy(allOtherVolRows, (item) => item.cuttings),
    };

    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.readFile(TEMPLATE_PATH);
    const dmrSheet = workbook.getWorksheet(DMR_SHEET_NAME);
    const inventorySheet = workbook.getWorksheet(INVENTORY_SHEET_NAME);
    if (!dmrSheet || !inventorySheet) throw new Error("Required sheets not found in assets/template.xlsx");

    workbook.views = [{ ...(workbook.views?.[0] ?? { visibility: "visible" }), firstSheet: 0, activeTab: 0 }];
    clearDmrDynamicAreas(dmrSheet);
    clearInventoryDynamicAreas(inventorySheet);

    fillDmrHeader(dmrSheet, { well, pad, report, wellGeneral, fluidName });
    fillDmrTopSections(dmrSheet, {
      drillStrings,
      casings: casingOpenHoleRows,
      summary,
      activePits,
      fluidName,
      wellGeneral,
      consumeProducts,
      mudReportState,
      solidsAnalysisRows,
    });
    fillDmrBottomSections(dmrSheet, {
      report,
      wellGeneral,
      pad,
      well,
      summary,
      pumps,
      productDailyCost,
      engineeringDailyCost,
      cuttingsAnalysis,
      reportFormat,
      shakers,
      otherSceRows,
    });
    fillInventoryHeader(inventorySheet, { well, pad, report, wellGeneral });
    fillInventorySheet(inventorySheet, {
      products,
      services,
      engineers,
      activePits,
      reservePits,
      activities: timeDistributionRows,
      productDailyCost,
      engineeringDailyCost,
      summary,
      cuttingsAnalysis,
      reportFormat,
    });

    const reportNumber = text(report?.userReportNo || report?.reportNo || wellGeneral?.reportNo, "1");
    const filename = `${safeFilename(well.wellNameNo || "daily_report")}_Report_${safeFilename(reportNumber)}.xlsx`;
    res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    res.setHeader("Content-Disposition", `attachment; filename=\"${filename}\"`);
    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: error.message });
  }
};
