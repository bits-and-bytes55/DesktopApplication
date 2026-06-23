import ExcelJS from "exceljs";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import InventorySnapshot from "../../modules/FullInventory/InventorySnapshot.js";
import Pit from "../../modules/pit/pit.model.js";
import Well from "../../modules/well/well.model.js";
import Pad from "../../modules/pad/pad.model.js";
import WellGeneral from "../../modules/wellGeneral/wellGeneralModel.js";
import Report from "../../modules/report/report.model.js";
import Engineer from "../../modules/engineers/engineer.model.js";
import Company from "../../modules/company/company.model.js";
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
import Nozzle from "../../modules/nozzle/nozzle.model.js";
import UgInventorySnapshot from "../../modules/ugInventory/ugInventoryProductModel.js";

const TEMPLATE_PATH = fileURLToPath(
  new URL("../../../assets/template.xlsx", import.meta.url)
);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PAD_LOGO_UPLOADS_ROOT = path.resolve(__dirname, "../../uploads/pad-logos");
const COMPANY_LOGO_UPLOADS_ROOT = path.resolve(__dirname, "../../uploads/company-logos");
const DMR_SHEET_NAME = "DMR";
const INVENTORY_SHEET_NAME = "Inventory";

const DMR_COLUMN_WIDTHS = [
  [1, 3, 2.26953125],
  [4, 4, 2.26953125],
  [5, 10, 2.26953125],
  [11, 11, 7.54296875],
  [12, 12, 2.26953125],
  [13, 13, 1.1796875],
  [14, 14, 5.453125],
  [15, 17, 2.26953125],
  [18, 18, 4.54296875],
  [19, 21, 2.26953125],
  [22, 22, 3],
  [23, 35, 2.26953125],
  [36, 42, 2.7265625],
  [43, 43, 3.453125],
  [44, 44, 5.7265625],
  [45, 45, 5.453125],
  [46, 52, 2.26953125],
  [53, 53, 3.7265625],
  [54, 54, 3],
  [55, 63, 2.26953125],
  [64, 64, 1.7265625],
  [65, 71, 2.26953125],
];
const INVENTORY_COLUMN_WIDTHS = [
  [1, 32, 5.7265625],
  [33, 80, 9.1796875],
];
const DMR_ROW_HEIGHTS = [
  [1, 1, 21],
  [2, 6, 12.75],
  [7, 82, 17.15],
  [83, 83, 22.5],
  [84, 97, 17.15],
  [98, 98, 15.65],
  [99, 101, 15.5],
  [102, 102, 16],
  [103, 104, 15.5],
  [105, 115, 15.65],
  [116, 116, 15.5],
  [117, 117, 12.75],
  [119, 124, 15.5],
];
const INVENTORY_ROW_HEIGHTS = [
  [1, 1, 26.25],
  [2, 4, 13],
  [5, 5, 26.25],
  [6, 6, 36.75],
  [7, 101, 17.15],
  [103, 103, 14.25],
];

const PRODUCT_ROWS = { start: 14, end: 63 };
const SERVICE_ROWS = { start: 76, end: 84 };
const ACTIVE_PIT_ROWS = { start: 77, end: 84 };
const TIME_ROWS = { start: 75, end: 84 };
const ENGINEERING_ROWS = { start: 87, end: 91 };
const RESERVE_ROWS = { start: 91, end: 101 };

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
const roundOrZero = (value, digits = 2) => {
  const raw = text(value);
  if (!raw) return "";
  const direct = Number(raw);
  const parsed = Number.isFinite(direct) ? direct : parseFraction(raw);
  if (parsed === null || !Number.isFinite(parsed)) return "";
  return round(parsed, digits);
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
const normalizeImageExtension = (extension = "") => {
  const cleaned = extension.replace(".", "").toLowerCase();
  if (cleaned === "jpg") return "jpeg";
  if (cleaned === "jpeg" || cleaned === "png") return cleaned;
  return "";
};
const resolveLogoImage = async (logoUrlValue, uploadsRoot) => {
  const logoUrl = text(logoUrlValue);
  if (!logoUrl) return null;

  const dataMatch = logoUrl.match(/^data:image\/(png|jpe?g);base64,(.+)$/i);
  if (dataMatch) {
    const extension = normalizeImageExtension(dataMatch[1]);
    const buffer = Buffer.from(dataMatch[2], "base64");
    return extension && buffer.length ? { buffer, extension } : null;
  }

  if (/^https?:\/\//i.test(logoUrl)) {
    try {
      const response = await fetch(logoUrl);
      if (response.ok) {
        const contentType = response.headers.get("content-type") || "";
        const extension =
          normalizeImageExtension(contentType.split("/").pop() || "") ||
          normalizeImageExtension(path.extname(new URL(logoUrl).pathname));
        const buffer = Buffer.from(await response.arrayBuffer());
        if (extension && buffer.length) return { buffer, extension };
      }
    } catch {
      // Fall back to local filename resolution below.
    }
  }

  let filename = "";
  try {
    filename = path.basename(new URL(logoUrl).pathname);
  } catch {
    filename = path.basename(logoUrl);
  }
  filename = decodeURIComponent(filename || "");
  if (!filename) return null;

  const logoPath = path.resolve(uploadsRoot, filename);
  if (!logoPath.startsWith(uploadsRoot) || !fs.existsSync(logoPath)) {
    return null;
  }

  const extension = normalizeImageExtension(path.extname(logoPath));
  if (!extension) return null;
  const buffer = fs.readFileSync(logoPath);
  return buffer.length ? { buffer, extension } : null;
};
const resolvePadLogoImage = (pad = {}) =>
  resolveLogoImage(pad?.clientLogoUrl, PAD_LOGO_UPLOADS_ROOT);
const resolveCompanyLogoImage = (company = {}) =>
  resolveLogoImage(company?.logoUrl, COMPANY_LOGO_UPLOADS_ROOT);
const clearTemplateLogos = (ws) => {
  if (Array.isArray(ws?._media)) ws._media = [];
};
const addLogoToSheet = (workbook, ws, logoImage, placement) => {
  if (!logoImage) return;
  const imageId = workbook.addImage(logoImage);
  ws.addImage(imageId, placement);
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
const lookupKey = (value) => text(value).toLowerCase().replace(/\s+/g, " ").trim();
const buildProductMetadataMap = (inventoryConfig) => {
  const map = new Map();
  for (const item of inventoryConfig?.products ?? []) {
    for (const key of [item.code, item.product].map(lookupKey).filter(Boolean)) {
      map.set(key, item);
    }
  }
  return map;
};
const productMetadataFor = (item, metadataMap = new Map()) =>
  metadataMap.get(lookupKey(item.code)) || metadataMap.get(lookupKey(item.product || item.itemName)) || {};
const isWeightMaterialProduct = (item, metadataMap) => {
  const meta = productMetadataFor(item, metadataMap);
  const group = lookupKey(meta.group || item.group);
  const name = lookupKey(item.product || item.itemName || meta.product);
  return group.includes("weight") || ["barite", "hematite", "haematite"].some((term) => name.includes(term));
};
const isBaseOilProduct = (item, metadataMap) => {
  const meta = productMetadataFor(item, metadataMap);
  const group = lookupKey(meta.group || item.group);
  const name = lookupKey(item.product || item.itemName || meta.product);
  return group.includes("base oil") || group.includes("base fluid") || name.includes("base oil");
};
const unitPackSize = (unit) => {
  const match = text(unit).match(/-?\d+(?:\.\d+)?/);
  return match ? toNumber(match[0], 1) : 1;
};
const unitPackMassLb = (unit, sgValue) => {
  const unitText = lookupKey(unit);
  const size = unitPackSize(unit);
  if (unitText.includes("ton")) return size * 2000;
  if (unitText.includes("kg")) return size * 2.20462;
  if (unitText.includes("lb")) return size;
  if (unitText.includes("gal")) {
    const sg = toNumber(sgValue);
    return sg > 0 ? size * 8.3454 * sg : 0;
  }
  return 0;
};
const productEndingConcentration = (item, summary, metadataMap) => {
  const explicit = roundOrZero(item.endingConcentration ?? item.endConc ?? item.end);
  if (explicit !== "") return explicit;

  const volumeBasis = toNumber(summary?.totalAdditions) || toNumber(summary?.finalActiveVolume);
  if (volumeBasis <= 0) return "";

  const meta = productMetadataFor(item, metadataMap);
  const massPerPackLb = unitPackMassLb(item.unit || meta.unit, item.sg ?? meta.sg);
  const used = toNumber(item.used ?? item.cumulativeUsed);
  if (massPerPackLb <= 0 || used <= 0) return "";
  return round((used * massPerPackLb) / volumeBasis, 2);
};
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
const setCellTextFit = (ws, address, { wrapText = true, shrinkToFit = true } = {}) => {
  const cell = ws.getCell(address);
  cell.alignment = {
    ...(cell.alignment || {}),
    wrapText,
    shrinkToFit,
  };
};
const fitColumnRange = (
  ws,
  column,
  startRow,
  endRow,
  options = { wrapText: true, shrinkToFit: true }
) => {
  for (let row = startRow; row <= endRow; row += 1) {
    setCellTextFit(ws, `${column}${row}`, options);
  }
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
const resolveIntervalFormationText = (intervals, intervalName) => {
  const normalizedTarget = normalizeIntervalKey(intervalName);

  if (normalizedTarget) {
    const exact = intervals.find(
      (interval) => normalizeIntervalKey(interval.name) === normalizedTarget
    );
    const exactFormation = text(exact?.formation);
    if (exactFormation) return exactFormation;
  }

  const firstWithFormation = intervals.find((interval) => text(interval.formation));
  return text(firstWithFormation?.formation);
};
const resolveWellActivityText = (wellGeneral) => {
  const direct = text(wellGeneral?.activity);
  if (direct) return direct;

  const rows = Array.isArray(wellGeneral?.timeDistributionRows)
    ? wellGeneral.timeDistributionRows
    : [];
  const firstRow = rows.find((row) => text(row?.description) || text(row?.activity));
  return firstText(firstRow?.description, firstRow?.activity);
};
const resolveWellFormationText = (wellGeneral, intervals = []) =>
  firstText(wellGeneral?.formation, resolveIntervalFormationText(intervals, wellGeneral?.interval));
const formatInclinationAzimuth = (wellGeneral) => {
  const inc = toNumber(wellGeneral?.inc);
  const azi = toNumber(wellGeneral?.azi);
  return inc || azi ? `${inc} / ${azi}` : "-";
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
const openHoleRowHasData = (row = {}) =>
  [row.description, row.id, row.md, row.washout].some((value) => text(value));
const isGenericCasingLabel = (value) => {
  const label = text(value).trim().toLowerCase();
  return label === "casing" || label === "liner";
};
const isSavedCasedHoleRow = (casing = {}) => {
  const description = text(casing.description).trim();
  const type = text(casing.type).trim();
  if (
    !description ||
    isGenericCasingLabel(description) ||
    isGenericCasingLabel(type)
  ) {
    return false;
  }
  return hasCasingData(casing);
};
const normalizeSavedOpenHoleRows = (wellGeneral = {}) => {
  const rows = Array.isArray(wellGeneral?.openHoleRows)
    ? wellGeneral.openHoleRows
    : [];

  return rows
    .filter(openHoleRowHasData)
    .map((row) => ({
      type: firstText(row.description, "Open Hole"),
      description: firstText(row.description, "Open Hole"),
      od: row.id,
      id: row.id,
      shoe: row.md,
      md: row.md,
      washout: row.washout,
    }));
};
const prepareSavedCasingOpenHoleRows = ({ casings, wellGeneral }) => [
  ...casings.filter(isSavedCasedHoleRow),
  ...normalizeSavedOpenHoleRows(wellGeneral),
].slice(0, 8);
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
  const constant = constants[pump.type] || constants.Triplex;
  return constant ? constant * linerId * linerId * strokeLength * efficiency : 0;
};
const getPumpDisplacement = (pump = {}) => {
  const saved = toNumber(pump.displacement);
  return saved > 0 ? saved : calculatePumpDisplacement(pump);
};
const getPumpRateGpm = (pump = {}) => {
  const saved = toNumber(pump.rate);
  if (saved > 0) return saved;

  const displacement = getPumpDisplacement(pump);
  const spm = toNumber(pump.spm);
  return displacement > 0 && spm > 0 ? displacement * spm * 42 : 0;
};
const summarizePumpFlow = (pumps = []) => {
  const activePumps = pumps.filter((pump) => toNumber(pump.spm) > 0);
  const sourcePumps = activePumps.length > 0 ? activePumps : pumps;

  return sourcePumps.reduce(
    (summary, pump) => {
      const displacement = getPumpDisplacement(pump);
      const spm = toNumber(pump.spm);
      const rateGpm = getPumpRateGpm(pump);
      const maxPumpP = toNumber(pump.maxPumpP);
      const surfaceLineVolume = calculatePipeVolume({
        id: pump.surfaceId,
        length: pump.surfaceLen,
      });

      return {
        displacementBblPerStroke:
          summary.displacementBblPerStroke + (spm > 0 ? displacement : 0),
        rateGpm: summary.rateGpm + rateGpm,
        spm: summary.spm + spm,
        maxPumpP: Math.max(summary.maxPumpP, maxPumpP),
        surfaceLineVolume: summary.surfaceLineVolume + surfaceLineVolume,
      };
    },
    {
      displacementBblPerStroke: 0,
      rateGpm: 0,
      spm: 0,
      maxPumpP: 0,
      surfaceLineVolume: 0,
    }
  );
};
const calculateCirculationTiming = (volumeBbl, pumpFlow = {}) => {
  const volume = toNumber(volumeBbl);
  if (volume <= 0) return { strokes: "", minutes: "" };

  const strokes =
    pumpFlow.displacementBblPerStroke > 0
      ? volume / pumpFlow.displacementBblPerStroke
      : 0;
  const minutes =
    pumpFlow.rateGpm > 0
      ? (volume * 42) / pumpFlow.rateGpm
      : pumpFlow.spm > 0 && strokes > 0
        ? strokes / pumpFlow.spm
        : 0;

  return {
    strokes: strokes > 0 ? round(strokes, 0) : "",
    minutes: minutes > 0 ? round(minutes, 1) : "",
  };
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
const applySheetLayout = (ws, columnWidths, rowHeights) => {
  columnWidths.forEach(([start, end, width]) => {
    for (let column = start; column <= end; column += 1) {
      ws.getColumn(column).width = width;
    }
  });

  rowHeights.forEach(([start, end, height]) => {
    for (let row = start; row <= end; row += 1) {
      ws.getRow(row).height = height;
    }
  });
};
const applyReportLayout = (dmrSheet, inventorySheet) => {
  applySheetLayout(dmrSheet, DMR_COLUMN_WIDTHS, DMR_ROW_HEIGHTS);
  applySheetLayout(inventorySheet, INVENTORY_COLUMN_WIDTHS, INVENTORY_ROW_HEIGHTS);
};
const applyRangeAlignment = (ws, startCell, endCell, alignment) => {
  const [, sc, sr] = startCell.match(/^([A-Z]+)(\d+)$/i) || [];
  const [, ec, er] = endCell.match(/^([A-Z]+)(\d+)$/i) || [];
  if (!sc || !sr || !ec || !er) return;
  for (let row = Number(sr); row <= Number(er); row += 1) {
    for (let col = columnToNumber(sc); col <= columnToNumber(ec); col += 1) {
      const cell = ws.getRow(row).getCell(col);
      cell.alignment = { ...(cell.alignment ?? {}), ...alignment };
    }
  }
};
const applyRangeBorder = (ws, startCell, endCell, border) => {
  const [, sc, sr] = startCell.match(/^([A-Z]+)(\d+)$/i) || [];
  const [, ec, er] = endCell.match(/^([A-Z]+)(\d+)$/i) || [];
  if (!sc || !sr || !ec || !er) return;
  for (let row = Number(sr); row <= Number(er); row += 1) {
    for (let col = columnToNumber(sc); col <= columnToNumber(ec); col += 1) {
      ws.getRow(row).getCell(col).border = border;
    }
  }
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
    ["A82", "AI98"], ["AJ36", "BS51"], ["AJ53", "BS86"], ["L92", "Q96"], ["AC92", "AI94"],
    ["AT91", "AY94"], ["BM91", "BS94"], ["AC96", "AI98"], ["AR96", "AX102"],
    ["BF97", "BS99"],
    ["L100", "AI105"], ["AR99", "AX101"], ["AD106", "AX109"],
    ["BF105", "BS108"], ["AT108", "AX111"],
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
  productMetadataMap = new Map(),
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
  const baseOilAddition = sumBy(
    productsUsed.filter((item) => isBaseOilProduct(item, productMetadataMap)),
    (item) => item.volumeBbl
  );
  const weightMaterialAddition = sumBy(
    productsUsed.filter((item) => isWeightMaterialProduct(item, productMetadataMap)),
    (item) => item.volumeBbl
  );
  const totalProductVolume = sumBy(productsUsed, (item) => item.volumeBbl);
  const totalProductAddition = Math.max(
    0,
    totalProductVolume - weightMaterialAddition - baseOilAddition
  );
  const totalOtherAddition = sumBy(otherVolRows, (item) => item.totalVolume);
  const volumeNotFluid = sumBy(otherVolRows, (item) => item.volumeNotFluid);
  const transferFromActive = sumBy(
    transferRows.filter((item) => isActiveSystemTarget(item.from)),
    (item) => item.totalTransferVol
  );
  const transferFromReserve = sumBy(
    transferRows.filter((item) => !isActiveSystemTarget(item.from)),
    (item) => item.totalTransferVol
  );
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
  const receivedFromReserve = totalReceived + transferFromReserve;
  const transferToReserve = transferFromActive + emptyTransferOut;
  const wholeMudAddition = totalReceived + totalOtherAddition;
  const totalAdditions =
    totalWaterAddition +
    receivedFromReserve +
    totalProductAddition +
    weightMaterialAddition +
    baseOilAddition +
    totalOtherAddition;
  const totalTransfersOut = transferToReserve + totalReturned;
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
  const surfaceLoss =
    lossBreakdown.shakersHydroclones +
    lossBreakdown.cuttingsRetention +
    lossBreakdown.centrifuge +
    lossBreakdown.evaporation +
    lossBreakdown.dumped +
    lossBreakdown.pitCleaning +
    lossBreakdown.tripping;
  const subsurfaceLoss = lossBreakdown.formation + lossBreakdown.others;
  const activeBuilt =
    activeWaterAddition +
    activeReceived +
    totalProductAddition +
    weightMaterialAddition +
    baseOilAddition +
    totalOtherAddition +
    transferFromReserve;
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
    receivedFromReserve: round(receivedFromReserve),
    transferredFromReserve: round(transferFromReserve),
    productAddition: round(totalProductAddition),
    weightMaterialAddition: round(weightMaterialAddition),
    baseOilAddition: round(baseOilAddition),
    waterAddition: round(totalWaterAddition),
    wholeFluidAddition: round(totalOtherAddition),
    inventoryWholeMudAddition: round(wholeMudAddition),
    totalAdditions: round(totalAdditions),
    transferToReserve: round(transferToReserve),
    returnToWarehouse: round(totalReturned),
    totalTransfersOut: round(totalTransfersOut),
    totalLoss: round(totalLoss),
    surfaceLoss: round(surfaceLoss),
    subsurfaceLoss: round(subsurfaceLoss),
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

const fillDmrHeader = (ws, { well, pad, report, wellGeneral, fluidName, intervals = [] }) => {
  const reportNumber = text(report?.userReportNo || report?.reportNo || wellGeneral?.userReportNo || wellGeneral?.reportNo, "1");
  const formationText = resolveWellFormationText(wellGeneral, intervals);
  const activityText = resolveWellActivityText(wellGeneral);
  setCellValue(ws, "AC7", text(report?._id || well?._id || well?.apiWellNo));
  setCellValue(ws, "AT7", formatDate(report?.reportDate || wellGeneral?.date, getReportDate()));
  setCellValue(ws, "BB2", reportNumber);
  setCellValue(ws, "BL7", reportNumber);
  setCellValue(ws, "H8", displayText(well?.wellNameNo));
  setCellValue(ws, "S8", "Rig Name");
  setCellValue(ws, "AB8", displayText(pad?.rig));
  setCellValue(ws, "AM8", "Field/Block");
  setCellValue(ws, "AT8", displayText(pad?.fieldBlock));
  setCellValue(ws, "BE8", "Location/State");
  setCellValue(ws, "BL8", displayText(pad?.country || pad?.stateProvince));
  setCellValue(ws, "H9", displayText(pad?.operator));
  setCellValue(ws, "AB9", displayText(pad?.contractor));
  setCellValue(ws, "AT9", displayText(formationText));
  setCellValue(ws, "BL9", displayText(wellGeneral?.md, ""));
  setCellValue(ws, "H10", displayText(wellGeneral?.operatorRep || pad?.operatorRep));
  setCellValue(ws, "AB10", displayText(wellGeneral?.contractorRep || pad?.contractorRep));
  setCellValue(ws, "AT10", formatInclinationAzimuth(wellGeneral).replace(" / ", "/"));
  setCellValue(ws, "BL10", displayText(wellGeneral?.tvd, ""));
  setCellValue(ws, "H11", displayText(formatDate(well?.spudDate)));
  setCellValue(ws, "AB11", displayText(fluidName));
  setCellValue(ws, "AT11", displayText(activityText));
  setCellValue(ws, "BL11", displayText(wellGeneral?.depthDrilled, ""));
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
  const gel10s = findMudRow(
    mudReportState,
    (key) =>
      key.includes("gel") &&
      (key.includes("10s") || key.includes("10 s") || key.includes("10 sec"))
  );
  const gel10m = findMudRow(
    mudReportState,
    (key) =>
      key.includes("gel") &&
      (key.includes("10m") || key.includes("10 m") || key.includes("10 min"))
  );
  const gel30m = findMudRow(
    mudReportState,
    (key) =>
      key.includes("gel") &&
      (key.includes("30m") || key.includes("30 m") || key.includes("30 min"))
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
  const coarseLcm = findMudRow(mudReportState, (key) => key.includes("coarse lcm"));

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
    46: buildMudGroups(gel10s),
    47: buildMudGroups(gel10m),
    48: buildMudGroups(gel30m),
    49: buildMudGroups(apiFiltrate),
    50: buildMudGroups(apiCake),
    51: buildMudGroups(hthpTemp),
    52: buildMudGroups(hthpFiltrate),
    53: buildMudGroups(hthpCake),
    54: buildMudGroups(solids),
    55: buildMudGroups(oil),
    56: buildMudGroups(water),
    57: buildMudGroups(sand),
    58: buildMudGroups(mbt),
    59: buildMudGroups(ph),
    60: buildMudGroups(mudAlkalinity),
    61: buildMudGroups(filtratePf),
    62: buildMudGroups(filtrateMf),
    63: buildMudGroups(calcium),
    64: buildMudGroups(chlorides),
    65: buildMudGroups(totalHardness),
    66: buildMudGroups(excessLime),
    67: buildMudGroups(potassium),
    68: buildMudGroups(makeUpWaterChlorides),
    69: buildMudGroups(solidsAdjusted),
    70: buildMudGroups(fineLcm),
    71: buildMudGroups(coarseLcm),
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

const formatHydraulicTypeNumber = (value) => {
  const parsed = toNumber(value);
  return parsed > 0 ? parsed.toFixed(3) : "";
};
const firstHydraulicNumber = (...values) => {
  for (const value of values) {
    const parsed = parseFraction(value);
    if (parsed !== null && Number.isFinite(parsed) && parsed > 0) return parsed;
  }
  return 0;
};
const mudRowNumber = (row = [], preferredIndex = 0) => {
  const preferred = parseFraction(row[preferredIndex]);
  if (preferred !== null && Number.isFinite(preferred) && preferred > 0) return preferred;

  for (const value of row) {
    const parsed = parseFraction(value);
    if (parsed !== null && Number.isFinite(parsed) && parsed > 0) return parsed;
  }
  return 0;
};
const loadMudHydraulicValues = ({ mudReportState, activePits = [] }) => {
  const mw = findMudRow(
    mudReportState,
    (key) => key === "mw" || key.startsWith("mw ") || key.includes("mud weight")
  );
  const pv = findMudRow(
    mudReportState,
    (key) => (key === "pv" || key.startsWith("pv ")) && !key.includes("for")
  );
  const yp = findMudRow(mudReportState, (key) => key === "yp" || key.startsWith("yp "));

  return {
    mw: firstHydraulicNumber(
      mudRowNumber(mw),
      activePits[0]?.density,
      activePits[1]?.density
    ),
    pv: mudRowNumber(pv),
    yp: mudRowNumber(yp),
  };
};
const nozzleTotalArea = (nozzleData = {}) => {
  const saved = toNumber(nozzleData?.tfa);
  if (saved > 0) return saved;

  const nozzles = Array.isArray(nozzleData?.nozzles) ? nozzleData.nozzles : [];
  return sumBy(nozzles, (nozzle) => {
    const count = toNumber(nozzle.count);
    const size32 = firstHydraulicNumber(nozzle.size32, nozzle.size, nozzle.diameterInch);
    const diameterIn = toNumber(nozzle.diameterInch) > 0 ? toNumber(nozzle.diameterInch) : size32 / 32;
    return count > 0 && diameterIn > 0 ? count * 0.785 * diameterIn * diameterIn : 0;
  });
};
const distributeHydraulicLoss = (total, weights = []) => {
  const cleanTotal = Math.max(0, toNumber(total));
  const cleanWeights = weights.map((value) => Math.max(0, toNumber(value)));
  const weightTotal = sumBy(cleanWeights, (value) => value);
  if (cleanTotal <= 0 || weightTotal <= 0) return cleanWeights.map(() => 0);
  return cleanWeights.map((value) => (cleanTotal * value) / weightTotal);
};
const pressurePercentText = (loss, total) => {
  const cleanLoss = Math.max(0, toNumber(loss));
  const cleanTotal = Math.max(0, toNumber(total));
  const percent = cleanTotal > 0 ? (cleanLoss / cleanTotal) * 100 : 0;
  return `${round(cleanLoss, 0)}/${round(percent, 1)}`;
};
const hydraulicDepthValue = (...values) => {
  const parsed = firstHydraulicNumber(...values);
  return parsed > 0 ? parsed : 0;
};
const calculateEcd = (mw, pressureLoss, depth) => {
  const baseMw = toNumber(mw);
  const loss = toNumber(pressureLoss);
  const depthFt = toNumber(depth);
  if (baseMw <= 0) return "";
  if (loss <= 0 || depthFt <= 0) return round(baseMw, 2);
  return round(baseMw + loss / (0.052 * depthFt), 2);
};
const hydraulicCriticalVelocity = ({ mw, pv, yp, holeSize, pipeOd }) => {
  const gap = Math.max(0, toNumber(holeSize) - toNumber(pipeOd));
  if (toNumber(mw) <= 0 || gap <= 0) return "";
  const base = 180 + toNumber(pv) * 1.4 + toNumber(yp) * 0.9;
  const gapAdjustment = clamp(gap / Math.max(toNumber(holeSize), 1), 0.2, 1) * 18;
  return round(Math.max(0, base + gapAdjustment), 1);
};
const buildHydraulicSegments = ({ drillStrings = [], casings = [], intervals = [], wellGeneral }) => {
  const intervalBitSize = resolveIntervalBitSize(intervals, wellGeneral?.interval);
  const firstCasingWithSize = casings.find((item) =>
    firstHydraulicNumber(item?.bit, item?.od, item?.id)
  );
  const holeSize = firstHydraulicNumber(
    intervalBitSize,
    firstCasingWithSize?.bit,
    firstCasingWithSize?.od,
    firstCasingWithSize?.id,
    wellGeneral?.bitSize
  );

  return drillStrings
    .filter((item) =>
      firstHydraulicNumber(item?.od) > 0 &&
      firstHydraulicNumber(item?.id) > 0 &&
      firstHydraulicNumber(item?.length) > 0
    )
    .slice(0, 5)
    .map((item) => ({
      holeSize,
      pipeOd: firstHydraulicNumber(item.od),
      pipeId: firstHydraulicNumber(item.id),
      length: firstHydraulicNumber(item.length),
    }));
};
const fillDmrHydraulicsRows = (ws, {
  drillStrings,
  casings,
  intervals,
  wellGeneral,
  activePits,
  mudReportState,
  pumps,
  report,
  nozzleData,
}) => {
  const mud = loadMudHydraulicValues({ mudReportState, activePits });
  const pumpFlow = summarizePumpFlow(pumps);
  const pumpRateAndPressure = report?.pumpRateAndPressure || {};
  const pumpRate = firstHydraulicNumber(pumpRateAndPressure.pumpRate, pumpFlow.rateGpm);
  const totalPressureLoss = firstHydraulicNumber(pumpRateAndPressure.pumpPressure, pumpFlow.maxPumpP);
  const dhToolsLoss = firstHydraulicNumber(pumpRateAndPressure.dhToolsPressureLoss);
  const motorLoss = firstHydraulicNumber(pumpRateAndPressure.motorPressureLoss);
  const segments = buildHydraulicSegments({ drillStrings, casings, intervals, wellGeneral });

  const remainingPressure = Math.max(0, totalPressureLoss - dhToolsLoss - motorLoss);
  const bitLoss = remainingPressure > 0 ? remainingPressure * 0.65 : 0;
  const dsLossTotal = remainingPressure > 0 ? remainingPressure * 0.25 : 0;
  const annLossTotal = remainingPressure > 0 ? remainingPressure * 0.10 : 0;
  const dsLosses = distributeHydraulicLoss(
    dsLossTotal,
    segments.map((item) => item.length / Math.max(Math.pow(item.pipeId, 4), 0.0001))
  );
  const annLosses = distributeHydraulicLoss(
    annLossTotal,
    segments.map((item) => {
      const hydraulicDiameter = Math.max(item.holeSize - item.pipeOd, 0.0001);
      return item.length / Math.pow(hydraulicDiameter, 3);
    })
  );
  const tfa = nozzleTotalArea(nozzleData);
  const bitSize = firstHydraulicNumber(
    resolveIntervalBitSize(intervals, wellGeneral?.interval),
    casings.find((item) => text(item?.bit))?.bit,
    segments[0]?.holeSize
  );
  const bitArea = bitSize > 0 ? 0.785 * bitSize * bitSize : 0;
  const bitJetVelocity = pumpRate > 0 && tfa > 0 ? (0.408 * pumpRate) / tfa : 0;
  const bitHhp = bitLoss > 0 && pumpRate > 0 ? (bitLoss * pumpRate) / 1714 : 0;
  const hsi = bitHhp > 0 && bitArea > 0 ? bitHhp / bitArea : 0;
  const tdDepth = hydraulicDepthValue(wellGeneral?.tvd, wellGeneral?.md, wellGeneral?.depthDrilled);
  const shoeDepth = hydraulicDepthValue(
    [...casings].reverse().find((item) => firstHydraulicNumber(item?.shoe))?.shoe,
    tdDepth
  );

  fillRowRange(ws, 82, "A", "AI", "Rheology/Hydraulics");
  [
    [83, "Type"],
    [84, "Length (ft)"],
    [85, "Ann. Vel. (ft/min)"],
    [86, "Crit. Vel (ft/min)"],
    [87, "DS Vel (ft/min)"],
    [88, "DS P. Loss (psi)"],
    [89, "Ann. P. Loss (psi)"],
  ].forEach(([row, label]) => fillRowRange(ws, row, "A", "H", label));

  const columns = [["I", "K"], ["L", "O"], ["P", "T"], ["U", "Y"], ["Z", "AD"], ["AE", "AI"]];
  columns.forEach(([start, end], index) => {
    const item = segments[index];
    const annArea = item ? Math.max(item.holeSize * item.holeSize - item.pipeOd * item.pipeOd, 0) : 0;
    const annVel = item && pumpRate > 0 && annArea > 0 ? (24.51 * pumpRate) / annArea : 0;
    const dsVel = item && pumpRate > 0 && item.pipeId > 0 ? (24.51 * pumpRate) / (item.pipeId * item.pipeId) : 0;
    fillRowRange(
      ws,
      83,
      start,
      end,
      item
        ? `${formatHydraulicTypeNumber(item.holeSize)} x ${formatHydraulicTypeNumber(item.pipeOd)} x ${formatHydraulicTypeNumber(item.pipeId)}`
        : ""
    );
    fillRowRange(ws, 84, start, end, item ? round(item.length, 1) : "");
    fillRowRange(ws, 85, start, end, annVel > 0 ? round(annVel, 1) : "");
    fillRowRange(
      ws,
      86,
      start,
      end,
      item ? hydraulicCriticalVelocity({ ...mud, holeSize: item.holeSize, pipeOd: item.pipeOd }) : ""
    );
    fillRowRange(ws, 87, start, end, dsVel > 0 ? round(dsVel, 1) : "");
    fillRowRange(ws, 88, start, end, totalPressureLoss > 0 ? round(dsLosses[index] || 0, 0) : "");
    fillRowRange(ws, 89, start, end, totalPressureLoss > 0 ? round(annLosses[index] || 0, 0) : "");
  });

  fillRowRange(ws, 90, "A", "T", "Pressure Losses");
  fillRowRange(ws, 90, "U", "AI", "ECD/ESD");
  [
    [91, "Total P. Loss (psi)", totalPressureLoss > 0 ? round(totalPressureLoss, 0) : ""],
    [92, "Bit Loss (psi/%)", totalPressureLoss > 0 ? pressurePercentText(bitLoss, totalPressureLoss) : ""],
    [93, "DS Loss (psi/%)", totalPressureLoss > 0 ? pressurePercentText(dsLossTotal, totalPressureLoss) : ""],
    [94, "Ann. Loss (psi/%)", totalPressureLoss > 0 ? pressurePercentText(annLossTotal, totalPressureLoss) : ""],
    [95, "DH Tools P. Loss (psi/%)", totalPressureLoss > 0 ? pressurePercentText(dhToolsLoss, totalPressureLoss) : ""],
    [96, "Motor P. Loss (psi/%)", totalPressureLoss > 0 ? pressurePercentText(motorLoss, totalPressureLoss) : ""],
  ].forEach(([row, label, value]) => {
    fillRowRange(ws, row, "A", "K", label);
    fillRowRange(ws, row, "L", "T", value);
  });

  [
    [91, "ECD /+ Cut at Shoe (ppg)", calculateEcd(mud.mw, annLossTotal, shoeDepth)],
    [92, "ECD /+ Cut at TD (ppg)", calculateEcd(mud.mw, annLossTotal, tdDepth)],
    [93, "ESD /+ Cut at Shoe (ppg)", mud.mw > 0 ? round(mud.mw, 2) : ""],
    [94, "ESD /+ Cut at TD (ppg)", mud.mw > 0 ? round(mud.mw, 2) : ""],
    [95, "Bit Data/Fluid Properties", "Bit Data/Fluid Properties"],
    [96, "Bit JV (ft/s)", bitJetVelocity > 0 ? round(bitJetVelocity, 1) : ""],
    [97, "Bit HHP (HP)/HSI", bitHhp > 0 ? `${round(bitHhp, 1)}/${round(hsi, 2)}` : ""],
    [98, "PV/YP", mud.pv > 0 || mud.yp > 0 ? `${round(mud.pv, 1)}/${round(mud.yp, 1)}` : ""],
  ].forEach(([row, label, value]) => {
    fillRowRange(ws, row, "U", "AD", label);
    fillRowRange(ws, row, "AE", "AI", value);
  });
};

const normalizeSceKey = (value) => text(value).toLowerCase().replace(/\s+/g, " ").trim();
const sceHasText = (row = {}, fields = []) =>
  fields.some((field) => text(row?.[field]));
const displayShakerTypeLabel = (value) => {
  const label = text(value);
  const numeric = Number(label);
  if (Number.isInteger(numeric) && numeric >= 1 && numeric <= 10) {
    return `Shaker ${numeric}`;
  }
  const match = label.toLowerCase().match(/^shaker\s+(\d+)$/);
  if (match) return `Shaker ${match[1]}`;
  return label;
};
const shakerSortValue = (row = {}) => {
  const number = Number(text(displayShakerTypeLabel(row.shaker)).match(/\d+/)?.[0]);
  return Number.isFinite(number) ? number : 999;
};
const latestTimestamp = (row = {}) =>
  new Date(row?.updatedAt ?? row?.createdAt ?? 0).getTime();
const shakerDataFields = [
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
  "hours",
  "oocWt",
];
const mergeSceField = (primary = {}, secondary = {}, field) =>
  firstMeaningfulText(primary?.[field], secondary?.[field]);
const mergeShakerRows = (left = {}, right = {}) => {
  const primary = latestTimestamp(right) >= latestTimestamp(left) ? right : left;
  const secondary = primary === right ? left : right;
  const merged = { ...secondary, ...primary };

  shakerDataFields.forEach((field) => {
    merged[field] = mergeSceField(primary, secondary, field);
  });
  merged.shaker = displayShakerTypeLabel(
    firstMeaningfulText(primary.shaker, secondary.shaker)
  );
  return merged;
};
const dedupeShakerRows = (rows = []) => {
  const byKey = new Map();

  rows.forEach((row) => {
    const key = normalizeSceKey(displayShakerTypeLabel(row?.shaker));
    if (!key) return;
    const existing = byKey.get(key);
    byKey.set(key, existing ? mergeShakerRows(existing, row) : row);
  });

  return Array.from(byKey.values());
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
  const screenText = firstText(screens.join("/"), row.screens);
  return screenText;
};
const otherSceModelInfo = (row = {}) =>
  [row.model1, row.model2, row.model3].map((value) => text(value)).filter(Boolean).join("/");
const sceHours = (row = {}) => roundOrBlank(firstMeaningfulText(row.time, row.hours), 2);
const otherSceInInfo = (row = {}) =>
  firstMeaningfulText(row.uf, row.in, row.inPpg, row.inlet, row.inletPpg, otherSceModelInfo(row));
const otherSceOutInfo = (row = {}) =>
  firstMeaningfulText(row.of, row.out, row.outPpg, row.outlet, row.outletPpg);
const fillDmrSceRows = (ws, { shakers = [], otherSceRows = [] }) => {
  const shakerRows = dedupeShakerRows(
    [...shakers].filter((row) =>
      sceHasText(row, shakerDataFields)
    )
  )
    .sort((left, right) => shakerSortValue(left) - shakerSortValue(right))
    .slice(0, 3);

  [97, 98, 99].forEach((row, index) => {
    const item = shakerRows[index];
    fillRowRange(ws, row, "AY", "BE", item ? displayShakerTypeLabel(item.shaker) : "");
    fillRowRange(ws, row, "BF", "BO", item ? shakerScreenInfo(item) : "");
    fillRowRange(ws, row, "BP", "BS", item ? sceHours(item) : "");
  });

  const availableOtherRows = otherSceRows.filter((row) =>
    sceHasText(row, ["type", "model1", "model2", "model3", "uf", "of", "time"])
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
    fillRowRange(ws, row, "AY", "BE", item ? firstText(item?.type, label) : "");
    fillRowRange(ws, row, "BF", "BJ", item ? otherSceInInfo(item) : "");
    fillRowRange(ws, row, "BK", "BO", item ? otherSceOutInfo(item) : "");
    fillRowRange(ws, row, "BP", "BS", item ? sceHours(item) : "");
  });
};

const normalizePersonName = (value) =>
  text(value).toLowerCase().replace(/\s+/g, " ").trim();
const normalizeLookupValue = (value) =>
  text(value).toLowerCase().replace(/\s+/g, " ").trim();
const engineerFullName = (engineer = {}) =>
  [engineer.firstName, engineer.lastName].map((value) => text(value)).filter(Boolean).join(" ");
const uniqueTextValues = (values = []) => {
  const seen = new Set();
  const result = [];
  for (const value of values.map((item) => text(item)).filter(Boolean)) {
    const key = value.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(value);
  }
  return result;
};
const loadExportFluidEngineers = async (wellGeneral) => {
  const selectedValues = uniqueTextValues([wellGeneral?.engineer, wellGeneral?.engineer2]);
  if (selectedValues.length === 0) return [];

  const engineers = await Engineer.find({}).lean();
  const byName = new Map();
  const byId = new Map();
  const byEmail = new Map();

  for (const engineer of engineers) {
    const fullName = normalizePersonName(engineerFullName(engineer));
    const id = text(engineer?._id);
    const email = normalizeLookupValue(engineer?.email);

    if (fullName && !byName.has(fullName)) {
      byName.set(fullName, engineer);
    }
    if (id && !byId.has(id)) {
      byId.set(id, engineer);
    }
    if (email && !byEmail.has(email)) {
      byEmail.set(email, engineer);
    }
  }

  return selectedValues.map((value) => {
    const normalized = normalizeLookupValue(value);
    const match =
      byId.get(text(value)) ||
      byEmail.get(normalized) ||
      byName.get(normalizePersonName(value));
    return {
      name: engineerFullName(match) || value,
      phone: firstText(match?.cell, match?.office),
      email: text(match?.email),
    };
  });
};
const fillDmrFluidEngineers = (ws, fluidEngineers = []) => {
  fillRowRange(ws, 106, "AD", "AX", "Fluid Engineer(s)");
  fillRowRange(ws, 107, "AD", "AX", fluidEngineers.map((item) => item.name).filter(Boolean).join(" / "));
  fillRowRange(ws, 108, "AD", "AX", fluidEngineers.map((item) => item.phone).filter(Boolean).join(" / "));
  fillRowRange(ws, 109, "AD", "AX", fluidEngineers.map((item) => item.email).filter(Boolean).join(" / "));
};

const fillDmrBitInformation = (ws, { casings = [], intervals = [], wellGeneral, reportFormat, nozzleData }) => {
  const rawBitSize = parseFraction(wellGeneral?.bitSize);
  const bitSize = rawBitSize
    ? round(convertLength(rawBitSize, "in", reportFormat.diameterUnit), reportFormat.digits)
    : "";
  const nozzles = Array.isArray(nozzleData?.nozzles) ? nozzleData.nozzles : [];

  fillRowRange(ws, 13, "BE", "BK", "Bit Type");
  fillRowRange(ws, 13, "BL", "BS", text(wellGeneral?.bitType));
  fillRowRange(ws, 14, "BE", "BK", "Bit Model");
  fillRowRange(ws, 14, "BL", "BS", text(wellGeneral?.bitMft));
  fillRowRange(
    ws,
    15,
    "BE",
    "BK",
    `Bit Size (${unitSuffix(reportFormat.diameterUnit, "in")})`
  );
  fillRowRange(ws, 15, "BL", "BS", bitSize);
  fillRowRange(ws, 16, "BE", "BS", "Nozzles");
  fillRowRange(ws, 17, "BE", "BK", "Number");
  fillRowRange(ws, 17, "BL", "BS", "Size");

  [18, 19, 20].forEach((row, index) => {
    const nozzle = nozzles[index];
    fillRowRange(ws, row, "BE", "BK", nozzle ? roundOrBlank(nozzle.count, 0) : "");
    fillRowRange(ws, row, "BL", "BS", nozzle ? roundOrBlank(nozzle.size32, 0) : "");
  });

  fillRowRange(ws, 21, "BE", "BK", "TFA (in2)");
  fillRowRange(ws, 21, "BL", "BS", roundOrBlank(nozzleData?.tfa, 3));
};

const fillDmrTopSections = (ws, { drillStrings, casings, summary, activePits, fluidName, wellGeneral, consumeProducts, mudReportState, solidsAnalysisRows, intervals, reportFormat, nozzleData }) => {
  const namedActivePits = activePits.filter((pit) => text(pit?.pitName));
  const namedConsumeProducts = consumeProducts.filter((item) =>
    firstText(item?.product, item?.itemName, item?.code)
  );

  for (let index = 0; index < 8; index += 1) {
    const row = 14 + index;
    const drill = drillStrings[index];
    const casing = casings[index];
    setCellValue(ws, `H${row}`, text(drill?.description));
    setCellValue(ws, `Q${row}`, drill ? round(drill.od, 3) : "");
    setCellValue(ws, `W${row}`, drill ? round(drill.id, 3) : "");
    setCellValue(ws, `AC${row}`, drill ? round(drill.length, 2) : "");
    const casingLabel = firstText(
      casing?.description,
      casing?.type,
      meaningfulText(casing?.id) ? `${meaningfulText(casing.id)}" OPEN HOLE` : ""
    );
    const casingOd = firstMeaningfulText(casing?.od, casing?.id, casing?.bit);
    const casingShoe = firstMeaningfulText(casing?.shoe, casing?.top);
    setCellValue(ws, `AJ${row}`, casingLabel);
    setCellValue(ws, `AS${row}`, roundOrBlank(casingOd, 3));
    setCellValue(ws, `AY${row}`, roundOrBlank(casingShoe, 2));
  }

  fillDmrBitInformation(ws, { casings, intervals, wellGeneral, reportFormat, nozzleData });

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
  applyRangeAlignment(ws, "AJ23", "AT34", {
    horizontal: "left",
    vertical: "middle",
    wrapText: false,
    shrinkToFit: true,
  });

  for (let index = 0; index < 12; index += 1) {
    const row = 23 + index;
    const pit = namedActivePits[index];
    setCellValue(ws, `BA${row}`, text(pit?.pitName));
    setCellValue(ws, `BN${row}`, pit ? round(getActivePitVolume(pit)) : "");
  }

  fillMudPropertyRows(ws, { mudReportState, activePits, fluidName, wellGeneral });
  fillDmrSolidsAnalysisRows(ws, solidsAnalysisRows);

  setCellValue(ws, "AJ36", "Product Name");
  setCellValue(ws, "AT36", "Size");
  setCellValue(ws, "AY36", "Used");
  setCellValue(ws, "BC36", "Cum. Used");
  setCellValue(ws, "BH36", "Unit Cost (Kwd)");
  setCellValue(ws, "BN36", "Daily Cost (Kwd)");

  for (let index = 0; index < 16; index += 1) {
    const row = 37 + index;
    const item = namedConsumeProducts[index];
    setCellValue(ws, `AJ${row}`, text(item?.product));
    setCellValue(ws, `AT${row}`, text(item?.unit));
    setCellValue(ws, `AY${row}`, item ? round(item.used) : "");
    setCellValue(ws, `BC${row}`, item ? round(item.used) : "");
    setCellValue(ws, `BH${row}`, item ? round(item.price, 3) : "");
    setCellValue(ws, `BN${row}`, item ? round(item.cost || item.price * item.used, 3) : "");
  }

  fitColumnRange(ws, "H", 14, 21);
  fitColumnRange(ws, "AJ", 14, 21);
  fitColumnRange(ws, "BA", 23, 34);
  fitColumnRange(ws, "AJ", 37, 52);
  fitColumnRange(ws, "AT", 37, 52);
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
  fluidEngineers,
  costSummary,
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

  setCellValue(ws, "AJ52", "Recommended Treatment");
  setCellValue(ws, "A72", "Solids Analysis");
  setCellValue(ws, "AJ72", "Operational Comments");
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
  setCellTextFit(ws, "AJ53", { wrapText: true, shrinkToFit: false });
  setCellTextFit(ws, "AJ73", { wrapText: true, shrinkToFit: false });

  pumps.slice(0, 4).forEach((pump, index) => {
    const startColumn = ["L", "R", "X", "AD"][index];
    const baseColumn = columnToNumber(startColumn);
    const displacement = getPumpDisplacement(pump);
    ws.getRow(100).getCell(baseColumn).value = index + 1;
    ws.getRow(101).getCell(baseColumn).value = roundOrBlank(pump.linerId, 3);
    ws.getRow(102).getCell(baseColumn).value = roundOrBlank(pump.strokeLength, 3);
    ws.getRow(103).getCell(baseColumn).value = roundOrBlank(pump.efficiency, 2);
    ws.getRow(104).getCell(baseColumn).value = roundOrBlank(pump.spm, 2);
    ws.getRow(105).getCell(baseColumn).value =
      displacement > 0 ? round(displacement, 4) : "";
  });

  const pumpFlow = summarizePumpFlow(pumps);
  const pumpRateAndPressure = report?.pumpRateAndPressure || {};
  const pumpPressure = firstMeaningfulText(
    pumpRateAndPressure.pumpPressure,
    pumpFlow.maxPumpP
  );
  const pumpRate = firstMeaningfulText(
    pumpRateAndPressure.pumpRate,
    pumpFlow.rateGpm
  );
  const circulationVolumes = [
    [99, summary.drillstringVolume + pumpFlow.surfaceLineVolume],
    [100, summary.annularVolume],
    [101, summary.drillstringVolume + summary.annularVolume + pumpFlow.surfaceLineVolume],
    [102, summary.finalActiveVolume],
  ];

  setCellValue(ws, "AT91", roundOrBlank(wellGeneral?.rpm, 2));
  setCellValue(ws, "AT92", roundOrBlank(wellGeneral?.rop, 2));
  setCellValue(ws, "AT93", roundOrBlank(wellGeneral?.wob, 2));
  setCellValue(ws, "AT94", roundOrBlank(wellGeneral?.bottomT, 2));
  setCellValue(ws, "BM91", roundOrBlank(wellGeneral?.puWt, 2));
  setCellValue(ws, "BM92", roundOrBlank(wellGeneral?.soWt, 2));
  setCellValue(ws, "BM93", roundOrBlank(wellGeneral?.onBottomTq, 2));
  setCellValue(ws, "BM94", roundOrBlank(wellGeneral?.offBottomTq, 2));
  fillRowRange(ws, 96, "AR", "AX", roundOrBlank(pumpPressure, 2));
  fillRowRange(ws, 97, "AR", "AX", roundOrBlank(pumpRate, 2));
  circulationVolumes.forEach(([row, volume]) => {
    const timing = calculateCirculationTiming(volume, pumpFlow);
    fillRowRange(ws, row, "AR", "AS", timing.strokes);
    fillRowRange(ws, row, "AT", "AX", timing.minutes);
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

  fillDmrSceRows(ws, { shakers, otherSceRows });
  fillDmrFluidEngineers(ws, fluidEngineers);
  fitColumnRange(ws, "AY", 97, 108);
  fitColumnRange(ws, "BF", 97, 108);
  fitColumnRange(ws, "BK", 101, 108);
  fitColumnRange(ws, "AD", 106, 109);

  const totalDailyCost = round(
    costSummary?.totalDailyCost ?? productDailyCost + engineeringDailyCost,
    3
  );
  const costValues = [
    round(costSummary?.dailyProductCost ?? productDailyCost, 3),
    round(costSummary?.sectionProductCost ?? productDailyCost, 3),
    round(costSummary?.dailyEngineeringCost ?? engineeringDailyCost, 3),
    round(costSummary?.sectionEngineeringCost ?? engineeringDailyCost, 3),
    round(costSummary?.cumProductCost ?? productDailyCost, 3),
    round(costSummary?.cumEngineeringCost ?? engineeringDailyCost, 3),
    totalDailyCost,
    round(costSummary?.totalWellCost ?? totalDailyCost, 3),
  ];
  DMR_COST_VALUE_CELLS.forEach((address, index) => setCellValue(ws, address, costValues[index] ?? ""));
};

const fillInventoryHeader = (ws, { well, pad, report, wellGeneral, fluidName, intervals = [] }) => {
  const formationText = resolveWellFormationText(wellGeneral, intervals);
  const activityText = resolveWellActivityText(wellGeneral);
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
  setCellValue(ws, "U9", displayText(formationText));
  setCellValue(ws, "AC9", displayText(wellGeneral?.md, ""));
  setCellValue(ws, "D10", displayText(wellGeneral?.operatorRep || pad?.operatorRep));
  setCellValue(ws, "L10", displayText(wellGeneral?.contractorRep || pad?.contractorRep));
  setCellValue(ws, "U10", formatInclinationAzimuth(wellGeneral));
  setCellValue(ws, "AC10", displayText(wellGeneral?.tvd, ""));
  setCellValue(ws, "D11", displayText(formatDate(well?.spudDate)));
  setCellValue(ws, "L11", displayText(fluidName));
  setCellValue(ws, "U11", displayText(activityText));
  setCellValue(ws, "AC11", displayText(wellGeneral?.depthDrilled, ""));
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
    .filter((item) => {
      if (!hasServiceCostData(item, nameField)) return false;
      return Boolean(firstText(item[nameField], item.itemName, item.code));
    })
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
  costSummary,
  productMetadataMap,
}) => {
  const productRows = products.filter((item) =>
    firstText(item?.itemName, item?.code, item?.product)
  );
  const serviceRows = services.filter((item) =>
    firstText(item?.itemName, item?.code)
  );
  const engineeringRows = engineers.filter((item) =>
    firstText(item?.itemName, item?.code)
  );
  const activePitRows = activePits.filter((pit) => text(pit?.pitName));
  const reservePitRows = reservePits.filter((pit) => text(pit?.pitName));
  const timeRows = activities.filter((activity) =>
    text(activity?.description) || toNumber(activity?.hours) > 0
  );

  setCellValue(ws, "A74", "Services");
  setCellValue(ws, "M74", "Pit Information");
  setCellValue(ws, "AA74", "Time Breakdown");
  setCellValue(ws, "A85", "Engineering");
  setCellValue(ws, "M89", "Reserve");
  applyRangeBorder(ws, "M88", "AD89", {
    bottom: { style: "thin", color: { argb: "FF000000" } },
    top: { style: "thin", color: { argb: "FF000000" } },
  });
  applyRangeBorder(ws, "M89", "AD101", {
    top: { style: "thin", color: { argb: "FF000000" } },
    left: { style: "thin", color: { argb: "FF000000" } },
    bottom: { style: "thin", color: { argb: "FF000000" } },
    right: { style: "thin", color: { argb: "FF000000" } },
  });
  setCellValue(ws, "A92", "Cost Summary");

  writeRows(ws, PRODUCT_ROWS, PRODUCT_COLUMNS, productRows, (item) => ({
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
    AC: roundOrZero(item.startingConcentration ?? item.startConc ?? item.start),
    AE: productEndingConcentration(item, summary, productMetadataMap),
  }));

  clearCells(ws, SUMMARY_VALUE_CELLS);
  [["G67", summary.inventoryWholeMudAddition ?? summary.wholeFluidAddition],["J67", summary.inventoryWholeMudAddition ?? summary.wholeFluidAddition],["M67", summary.inventoryWholeMudAddition ?? summary.wholeFluidAddition],
   ["G68", summary.baseOilAddition],["J68", summary.baseOilAddition],["M68", summary.baseOilAddition],
   ["G69", summary.waterAddition],["J69", summary.waterAddition],["M69", summary.waterAddition],
   ["G70", summary.productAddition],["J70", summary.productAddition],["M70", summary.productAddition],
   ["G71", summary.weightMaterialAddition],["J71", summary.weightMaterialAddition],["M71", summary.weightMaterialAddition],
   ["G72", summary.transferredFromReserve],["J72", summary.transferredFromReserve],["M72", summary.transferredFromReserve],
   ["G73", summary.totalAdditions],["J73", summary.totalAdditions],["M73", summary.totalAdditions],
   ["X67", summary.transferToReserve],["AA67", summary.transferToReserve],["AD67", summary.transferToReserve],
   ["X68", summary.returnToWarehouse],["AA68", summary.returnToWarehouse],["AD68", summary.returnToWarehouse],
   ["X71", summary.surfaceLoss],["AA71", summary.surfaceLoss],["AD71", summary.surfaceLoss],
   ["X72", summary.subsurfaceLoss],["AA72", summary.subsurfaceLoss],["AD72", summary.subsurfaceLoss],
   ["X73", summary.totalLoss],["AA73", summary.totalLoss],["AD73", summary.totalLoss]].forEach(
    ([address, value]) => setCellValue(ws, address, value)
  );

  writeRows(ws, SERVICE_ROWS, SERVICE_COLUMNS, serviceRows, (item) => ({
    A: item.itemName || "",
    G: round(item.used ?? item.cumulativeUsed ?? item.usage),
    I: round(item.cumulativeUsed ?? item.used ?? item.usage),
    K: round(item.costDollar, 3),
  }));
  writeRows(ws, ACTIVE_PIT_ROWS, PIT_COLUMNS, activePitRows, (pit) => ({
    M: pit.pitName || "",
    S: round(getPitVolume(pit)),
    U: round(pit.density),
    W: pit.fluidType || "",
  }));
  writeRows(ws, TIME_ROWS, TIME_COLUMNS, timeRows, (activity) => ({
    AA: activity.description || "",
    AE: round(activity.hours),
  }));
  writeRows(ws, ENGINEERING_ROWS, SERVICE_COLUMNS, engineeringRows, (item) => ({
    A: item.itemName || "",
    G: round(item.used ?? item.cumulativeUsed ?? item.usage),
    I: round(item.cumulativeUsed ?? item.used ?? item.usage),
    K: round(item.costDollar, 3),
  }));
  writeRows(ws, RESERVE_ROWS, PIT_COLUMNS, reservePitRows, (pit) => ({
    M: pit.pitName || "",
    S: round(getPitVolume(pit)),
    U: round(pit.density),
    W: pit.fluidType || "",
  }));
  fitColumnRange(ws, "A", 14, 63);
  fitColumnRange(ws, "F", 14, 63);
  fitColumnRange(ws, "A", 76, 84);
  fitColumnRange(ws, "M", 77, 84);
  fitColumnRange(ws, "AA", 75, 84);
  fitColumnRange(ws, "A", 87, 91);
  fitColumnRange(ws, "M", 91, 101);

  const totalDailyCost = round(
    costSummary?.totalDailyCost ?? productDailyCost + engineeringDailyCost,
    3
  );
  clearCells(ws, COST_SUMMARY_VALUE_CELLS);
  [["G94", costSummary?.dailyProductCost ?? productDailyCost],
   ["G95", costSummary?.sectionProductCost ?? productDailyCost],
   ["G96", costSummary?.dailyEngineeringCost ?? engineeringDailyCost],
   ["G97", costSummary?.sectionEngineeringCost ?? engineeringDailyCost],
   ["G98", costSummary?.cumProductCost ?? productDailyCost],
   ["G99", costSummary?.cumEngineeringCost ?? engineeringDailyCost],
   ["G100", totalDailyCost],
   ["G101", costSummary?.totalWellCost ?? totalDailyCost]].forEach(
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
    return scoped;
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
    return scoped;
  }

  const wellScopedLegacy = await DrillString.find({
    wellId,
    ...legacyReportScope(),
  })
    .sort({ createdAt: 1, _id: 1 })
    .limit(8)
    .lean();
  if (wellScopedLegacy.length > 0) return wellScopedLegacy;
  return [];
};

const loadExportCasings = async ({ wellId, reportId }) => {
  if (!wellId) return [];

  const filter = reportId ? { wellId, reportId } : { wellId };

  return Casing.find(filter).sort({ sortOrder: 1, createdAt: 1, _id: 1 }).lean();
};

const loadInventorySnapshot = async ({ wellId, reportId }) => {
  if (!wellId) return [];

  if (reportId) {
    const scoped = await InventorySnapshot.find({ wellId, reportId })
      .sort({ category: 1, itemName: 1 })
      .lean();
    return scoped;
  }

  const legacy = await InventorySnapshot.find({
    wellId,
    ...legacyReportScopeWithEmpty(),
  })
    .sort({ category: 1, itemName: 1 })
    .lean();
  if (legacy.length > 0) return legacy;
  return reportId
    ? []
    : InventorySnapshot.find({ wellId })
        .sort({ category: 1, itemName: 1 })
        .lean();
};

const normalizeCostCategory = (value) => text(value).toLowerCase();
const isProductCostCategory = (category) =>
  normalizeCostCategory(category) === "product";
const isEngineeringCostCategory = (category) =>
  ["service", "engineering", "package"].includes(normalizeCostCategory(category));
const snapshotCost = (row = {}) =>
  toNumber(row.costDollar) || toNumber(row.subtotal) || toNumber(row.totalDollar);
const summarizeCostRows = (rows = []) => {
  const productCost = sumBy(
    rows.filter((row) => isProductCostCategory(row.category)),
    snapshotCost
  );
  const engineeringCost = sumBy(
    rows.filter((row) => isEngineeringCostCategory(row.category)),
    snapshotCost
  );

  return {
    productCost: round(productCost, 3),
    engineeringCost: round(engineeringCost, 3),
    totalCost: round(productCost + engineeringCost, 3),
    hasRows: rows.length > 0,
  };
};
const reportOrderNumber = (report = {}) => {
  const parsed = Number(text(report.userReportNo || report.reportNo));
  return Number.isFinite(parsed) ? parsed : null;
};
const reportTimeValue = (report = {}) =>
  new Date(report.reportDate || report.createdAt || report.updatedAt || 0).getTime() || 0;
const sortReportsForCost = (reports = []) =>
  [...reports].sort((left, right) => {
    const leftNumber = reportOrderNumber(left);
    const rightNumber = reportOrderNumber(right);
    if (leftNumber !== null && rightNumber !== null && leftNumber !== rightNumber) {
      return leftNumber - rightNumber;
    }

    const timeDiff = reportTimeValue(left) - reportTimeValue(right);
    if (timeDiff !== 0) return timeDiff;
    return text(left._id).localeCompare(text(right._id));
  });
const loadCostReportIds = async ({ wellId, reportId, report }) => {
  if (!wellId || !reportId) return [];

  const reports = sortReportsForCost(await Report.find({ wellId }).lean());
  if (reports.length === 0) return [];

  const currentId = text(reportId || report?._id);
  const currentReport =
    reports.find((item) => text(item._id) === currentId) || report || null;
  if (!currentReport) return reports.map((item) => text(item._id)).filter(Boolean);

  const currentNumber = reportOrderNumber(currentReport);
  if (currentNumber !== null) {
    return reports
      .filter((item) => {
        const itemNumber = reportOrderNumber(item);
        if (itemNumber !== null) return itemNumber <= currentNumber;
        return reportTimeValue(item) <= reportTimeValue(currentReport);
      })
      .map((item) => text(item._id))
      .filter(Boolean);
  }

  const currentIndex = reports.findIndex((item) => text(item._id) === currentId);
  return (currentIndex >= 0 ? reports.slice(0, currentIndex + 1) : reports)
    .map((item) => text(item._id))
    .filter(Boolean);
};
const loadDmrCostSummary = async ({
  wellId,
  reportId,
  report,
  wellGeneral,
  currentRows,
  fallbackProductCost,
  fallbackEngineeringCost,
}) => {
  const daily = summarizeCostRows(currentRows);
  let cumulativeRows = currentRows;
  let sectionRows = currentRows;

  const reportIds = await loadCostReportIds({ wellId, reportId, report });
  if (reportIds.length > 0) {
    const historyRows = await InventorySnapshot.find({
      wellId,
      reportId: { $in: reportIds },
    }).lean();

    if (historyRows.length > 0) {
      cumulativeRows = historyRows;
      const currentInterval = normalizeIntervalKey(wellGeneral?.interval);

      if (currentInterval) {
        const wellGeneralRows = await WellGeneral.find({
          wellId,
          reportId: { $in: reportIds },
        })
          .select("reportId interval")
          .lean();
        const sectionReportIds = new Set(
          wellGeneralRows
            .filter((item) => normalizeIntervalKey(item.interval) === currentInterval)
            .map((item) => text(item.reportId))
            .filter(Boolean)
        );

        sectionRows =
          sectionReportIds.size > 0
            ? historyRows.filter((item) => sectionReportIds.has(text(item.reportId)))
            : historyRows;
      } else {
        sectionRows = historyRows;
      }
    }
  }

  const section = summarizeCostRows(sectionRows);
  const cumulative = summarizeCostRows(cumulativeRows);
  const dailyProductCost = daily.hasRows ? daily.productCost : round(fallbackProductCost, 3);
  const dailyEngineeringCost = daily.hasRows
    ? daily.engineeringCost
    : round(fallbackEngineeringCost, 3);
  const sectionProductCost = section.hasRows ? section.productCost : dailyProductCost;
  const sectionEngineeringCost = section.hasRows
    ? section.engineeringCost
    : dailyEngineeringCost;
  const cumProductCost = cumulative.hasRows ? cumulative.productCost : dailyProductCost;
  const cumEngineeringCost = cumulative.hasRows
    ? cumulative.engineeringCost
    : dailyEngineeringCost;

  return {
    dailyProductCost,
    sectionProductCost,
    dailyEngineeringCost,
    sectionEngineeringCost,
    cumProductCost,
    cumEngineeringCost,
    totalDailyCost: round(dailyProductCost + dailyEngineeringCost, 3),
    totalWellCost: round(cumProductCost + cumEngineeringCost, 3),
  };
};

const loadExportPumps = async ({ wellId, reportId }) => {
  if (!wellId) return [];

  if (reportId) {
    const scoped = await Pump.find({ wellId, reportId })
      .sort({ rowNumber: 1, updatedAt: -1, createdAt: -1, _id: -1 })
      .lean();

    return normalizePumpRows(scoped);
  }

  const legacy = await Pump.find({ wellId, ...legacyReportScopeForModel(Pump) })
    .sort({ rowNumber: 1, updatedAt: -1, createdAt: -1, _id: -1 })
    .lean();
  const normalizedLegacy = normalizePumpRows(legacy);
  if (normalizedLegacy.length > 0) {
    return normalizedLegacy;
  }
  return reportId
    ? []
    : normalizePumpRows(
        await Pump.find({ wellId })
          .sort({ rowNumber: 1, updatedAt: -1, createdAt: -1, _id: -1 })
          .lean()
      );
};

const loadExportWellGeneral = async ({ wellId, reportId, report }) => {
  if (!wellId) return null;

  if (reportId) {
    const byReportId = await WellGeneral.findOne({ wellId, reportId })
      .sort({ createdAt: -1, _id: -1 })
      .lean();
    if (byReportId) return byReportId;
  }

  for (const reportNumber of uniqueTextValues([
    report?.reportNo,
    report?.userReportNo,
  ])) {
    const byReportNumber = await WellGeneral.findOne({
      wellId,
      $or: [{ reportNo: reportNumber }, { userReportNo: reportNumber }],
    })
      .sort({ createdAt: -1, _id: -1 })
      .lean();
    if (byReportNumber) return byReportNumber;
  }

  if (reportId) return null;

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
    return scoped;
  }

  const legacy = await MudReportState.findOne({
    wellId,
    $or: [{ reportId: "" }, { reportId: null }, { reportId: { $exists: false } }],
  })
    .sort({ updatedAt: -1, _id: -1 })
    .lean();
  if (legacy) return legacy;
  return reportId
    ? null
    : MudReportState.findOne({ wellId })
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
  if (wellId && !reportId) {
    queries.push({ wellId, ...legacyReportScopeWithEmpty() });
    queries.push({ wellId });
  }
  if (reportId && !wellId) {
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

const loadExportSceRows = async (
  Model,
  { wellId, reportId, report },
  sort = { createdAt: 1, _id: 1 }
) => {
  if (!wellId && !reportId) return [];

  const queries = [];
  if (wellId && reportId) {
    queries.push({ wellId, reportId });
  }
  if (wellId) {
    for (const reportNumber of uniqueTextValues([
      report?.reportNo,
      report?.userReportNo,
    ])) {
      queries.push({ wellId, reportNo: reportNumber });
    }
  }
  if (wellId) {
    if (!reportId) {
      queries.push({ wellId, ...legacyReportScopeForModel(Model) });
      queries.push({ wellId });
    }
  }
  if (reportId) {
    queries.push({ reportId });
  }

  for (const query of queries) {
    const rows = await Model.find(query).sort(sort).lean();
    if (rows.length > 0) return rows;
  }

  return [];
};

const loadExportNozzle = async ({ wellId, reportId }) => {
  if (!wellId && !reportId) return null;

  const queries = [];
  if (wellId && reportId) {
    queries.push({ wellId, reportId });
  }
  if (wellId) {
    if (!reportId) {
      queries.push({ wellId, ...legacyReportScopeForModel(Nozzle) });
      queries.push({ wellId });
    }
  }
  if (reportId) {
    queries.push({ reportId });
  }

  for (const query of queries) {
    const row = await Nozzle.findOne(query)
      .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
      .lean();
    if (row) return row;
  }

  return null;
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
      inventoryData, well, drillStrings, casings, pumps, consumeProducts,
      liveServices, liveEngineering, addWaterRows, receiveMudRows, returnLostRows, transferRows, otherVolRows, mudLossRows, mudLossStorageRows,
      allOtherVolRows, intervals, mudReportState, solidsAnalysisRows, shakers, otherSceRows, emptyFluidRows, nozzleData, inventoryConfig,
    ] = await Promise.all([
      loadInventorySnapshot({ wellId, reportId }),
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
      loadExportSceRows(Shaker, { wellId, reportId, report }),
      loadExportSceRows(OtherSce, { wellId, reportId, report }),
      loadReportScopedList(EmptyFluidActiveSystem, { wellId, reportId }),
      loadExportNozzle({ wellId, reportId }),
      UgInventorySnapshot.findOne({ wellId }).sort({ updatedAt: -1 }).lean(),
    ]);
    if (!well) {
      return res.status(404).json({ success: false, message: "Well not found" });
    }

    const [pad, company, wellGeneral, pits] = await Promise.all([
      well?.padId ? Pad.findById(well.padId).lean() : null,
      Company.findOne().sort({ updatedAt: -1, createdAt: -1 }).lean(),
      loadExportWellGeneral({ wellId, reportId, report }),
      reportId
        ? loadMergedPits({ wellId, reportId })
        : Pit.find({ wellId }).sort({ createdAt: 1, _id: 1 }).lean(),
    ]);
    const fluidEngineers = await loadExportFluidEngineers(wellGeneral);

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
        : [];
    const products = inventoryData.filter((item) => item.category === "Product");
    const snapshotServices = inventoryData.filter((item) => item.category === "Service");
    const snapshotEngineering = inventoryData.filter((item) => item.category === "Engineering");
    const snapshotPackages = inventoryData.filter((item) => item.category === "Package");
    const serviceRows = normalizeServiceCostRows(liveServices, {
      category: "Service",
      nameField: "serviceName",
    });
    const engineeringRows = normalizeServiceCostRows(liveEngineering, {
      category: "Engineering",
      nameField: "engineeringName",
    });
    const baseServices = serviceRows.length > 0 ? serviceRows : snapshotServices;
    const services = [...baseServices, ...snapshotPackages];
    const engineers = engineeringRows.length > 0 ? engineeringRows : snapshotEngineering;
    const productMetadataMap = buildProductMetadataMap(inventoryConfig);
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
      productMetadataMap,
    });
    const productDailyCost = sumBy(products, snapshotCost);
    const serviceDailyCost = sumBy(baseServices, snapshotCost);
    const engineerDailyCost = sumBy(engineers, snapshotCost);
    const packageDailyCost = sumBy(snapshotPackages, snapshotCost);
    const engineeringDailyCost = serviceDailyCost + engineerDailyCost + packageDailyCost;
    const costSummary = await loadDmrCostSummary({
      wellId,
      reportId,
      report,
      wellGeneral,
      currentRows: inventoryData,
      fallbackProductCost: productDailyCost,
      fallbackEngineeringCost: engineeringDailyCost,
    });
    const intervalBitSize = resolveIntervalBitSize(intervals, wellGeneral?.interval);
    const casingOpenHoleRows = prepareSavedCasingOpenHoleRows({
      casings,
      wellGeneral,
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

    clearTemplateLogos(dmrSheet);
    clearTemplateLogos(inventorySheet);

    const [companyLogoImage, padLogoImage] = await Promise.all([
      resolveCompanyLogoImage(company),
      resolvePadLogoImage(pad),
    ]);
    const leftLogoPlacement = {
      tl: { col: 0.25, row: 0.25 },
      ext: { width: 145, height: 52 },
      editAs: "oneCell",
    };
    addLogoToSheet(workbook, dmrSheet, companyLogoImage, leftLogoPlacement);
    addLogoToSheet(workbook, inventorySheet, companyLogoImage, leftLogoPlacement);
    addLogoToSheet(workbook, dmrSheet, padLogoImage, {
      tl: { col: 63.2, row: 0.25 },
      ext: { width: 110, height: 60 },
      editAs: "oneCell",
    });
    addLogoToSheet(workbook, inventorySheet, padLogoImage, {
      tl: { col: 29.5, row: 0.25 },
      ext: { width: 110, height: 60 },
      editAs: "oneCell",
    });

    fillDmrHeader(dmrSheet, { well, pad, report, wellGeneral, fluidName, intervals });
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
      intervals,
      reportFormat,
      nozzleData,
    });
    fillDmrHydraulicsRows(dmrSheet, {
      drillStrings,
      casings: casingOpenHoleRows,
      intervals,
      wellGeneral,
      activePits,
      mudReportState,
      pumps,
      report,
      nozzleData,
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
      fluidEngineers,
      costSummary,
    });
    fillInventoryHeader(inventorySheet, { well, pad, report, wellGeneral, fluidName, intervals });
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
      costSummary,
      productMetadataMap,
    });
    applyReportLayout(dmrSheet, inventorySheet);

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
