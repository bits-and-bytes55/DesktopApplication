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
import ConsumeProductDistributionState from "../../modules/Consumeproduct/ConsumeProductDistributionState.js";
import ReceiveMud from "../../modules/receivemud/ReceiveMud.js";
import ReturnLostMud from "../../modules/returnlostmud/ReturnLostMud.js";
import TransferMud from "../../modules/transfermud/TransferMud.js";
import OtherVolAddition from "../../modules/othervol/OtherVolAddition.js";
import MudLoss from "../../modules/mudloss/MudLoss.js";
import MudLossStorage from "../../modules/mudlossstorage/MudLossStorage.js";
import { Interval } from "../../modules/wellInterval/intervalModel.js";
import MudReportState from "../../modules/mudReport/MudReportState.js";
import SolidsAnalysis from "../../modules/SolidAnalysis/solidanalysismodel.js";
import { Shaker, OtherSce } from "../../modules/sce/sce.model.js";
import EmptyFluidActiveSystem from "../../modules/emptyfluidactivesystem/EmptyFluidActiveSystem.js";
import Nozzle from "../../modules/nozzle/nozzle.model.js";
import SurveyConfig from "../../modules/survey/survey.model.js";
import UgInventorySnapshot from "../../modules/ugInventory/ugInventoryProductModel.js";
import { calculateCombinedHoleVolumeResult } from "../pitvolumename/volumeName.controller.js";

const TEMPLATE_PATH = fileURLToPath(
  new URL("../../../assets/template.xlsx", import.meta.url)
);
const COST_OF_PAD_TEMPLATE_PATH = fileURLToPath(
  new URL("../../../assets/cost_of_pad_template.xlsx", import.meta.url)
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
const rowTimestamp = (item = {}) =>
  new Date(item.updatedAt || item.createdAt || 0).getTime();
const latestPitsByNameForExport = (items = []) => {
  const latestByName = new Map();
  for (const item of items) {
    const key = text(item?.pitName).toLowerCase();
    if (!key) continue;
    const existing = latestByName.get(key);
    if (!existing || rowTimestamp(item) >= rowTimestamp(existing)) {
      latestByName.set(key, item);
    }
  }
  return [...latestByName.values()].sort((left, right) => {
    const leftOrder = Number(left?.sortOrder);
    const rightOrder = Number(right?.sortOrder);
    if (
      Number.isFinite(leftOrder) &&
      Number.isFinite(rightOrder) &&
      leftOrder !== rightOrder
    ) {
      return leftOrder - rightOrder;
    }
    return rowTimestamp(left) - rowTimestamp(right);
  });
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
const prepareInventoryHeaderLayout = (ws) => {
  const titleStyle = { ...ws.getCell("I2").style };
  const reportNoStyle = { ...ws.getCell("V2").style };
  const boxBorder = { style: "medium", color: { argb: "FF000000" } };
  try {
    ws.unMergeCells("I2:U5");
  } catch {}
  try {
    ws.unMergeCells("V2:W5");
  } catch {}
  try {
    ws.unMergeCells("H2:V5");
  } catch {}
  try {
    ws.unMergeCells("W2:X5");
  } catch {}
  try {
    ws.unMergeCells("H2:X5");
  } catch {}
  try {
    ws.unMergeCells("Y2:Z5");
  } catch {}
  for (let row = 2; row <= 5; row += 1) {
    for (let col = 8; col <= 26; col += 1) {
      const cell = ws.getRow(row).getCell(col);
      cell.fill = titleStyle.fill;
      cell.alignment = { horizontal: "center", vertical: "middle" };
      cell.border = {};
    }
  }
  ws.mergeCells("H2:X5");
  ws.mergeCells("Y2:Z5");
  ws.getCell("H2").style = {
    ...titleStyle,
    alignment: { horizontal: "center", vertical: "middle" },
    font: {
      ...(titleStyle.font || {}),
      bold: false,
      size: 24,
      color: { argb: "FF000000" },
    },
  };
  ws.getCell("Y2").style = {
    ...reportNoStyle,
    alignment: { horizontal: "center", vertical: "middle" },
    font: {
      ...(reportNoStyle.font || {}),
      bold: false,
      size: 22,
      color: { argb: "FF000000" },
    },
  };
  for (let col = 8; col <= 26; col += 1) {
    ws.getCell(2, col).border = {
      ...ws.getCell(2, col).border,
      top: boxBorder,
    };
    ws.getCell(5, col).border = {
      ...ws.getCell(5, col).border,
      bottom: boxBorder,
    };
  }
  for (let row = 2; row <= 5; row += 1) {
    ws.getCell(row, 8).border = {
      ...ws.getCell(row, 8).border,
      left: boxBorder,
    };
    ws.getCell(row, 22).border = {
      ...ws.getCell(row, 22).border,
      right: undefined,
    };
    ws.getCell(row, 25).border = {
      ...ws.getCell(row, 25).border,
      left: boxBorder,
    };
    ws.getCell(row, 26).border = {
      ...ws.getCell(row, 26).border,
      right: boxBorder,
    };
  }
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
const getPitVolume = (pit) => pit?.volume ?? "";
const getActivePitVolume = (pit) => toNumber(pit?.volume);
const setCellValue = (ws, address, value = "") => {
  ws.getCell(address).value = value ?? "";
};
const normalizeCurrencyNumberFormat = (format) => {
  const raw = text(format, "0.00").trim();
  return /^0(?:\.0{1,4})?$/.test(raw) ? raw : "0.00";
};
const normalizeCurrencySymbol = (symbol) => {
  const raw = text(symbol, "Kwd").trim();
  const replacements = {
    "â‚¹": "\u20B9",
    "Â£": "\u00A3",
    "Â¥": "\u00A5",
    "â‚¬": "\u20AC",
    "â©": "\u00A9",
  };
  return replacements[raw] || raw || "Kwd";
};
const isNumericExcelValue = (value) => {
  if (typeof value === "number") return Number.isFinite(value);
  if (value && typeof value === "object" && typeof value.result === "number") {
    return Number.isFinite(value.result);
  }
  return false;
};
const shouldKeepTemplateNumberFormat = (cell) => {
  const format = text(cell.numFmt).toLowerCase();
  if (!format) return false;
  return (
    format.includes("%") ||
    format.includes("@") ||
    format.includes("yy") ||
    format.includes("dd") ||
    format.includes("mm/") ||
    format.includes("/mm") ||
    format.includes("h:")
  );
};
const applyCompanyCurrencyFormatToWorksheet = (ws, company) => {
  const numberFormat = normalizeCurrencyNumberFormat(company?.currencyFormat);
  const currencySymbol = normalizeCurrencySymbol(company?.currencySymbol);
  ws.eachRow((row) => {
    row.eachCell({ includeEmpty: false }, (cell) => {
      if (typeof cell.value === "string" && currencySymbol) {
        cell.value = cell.value.replace(/\bKwd\b/g, currencySymbol);
      }
      if (isNumericExcelValue(cell.value) && !shouldKeepTemplateNumberFormat(cell)) {
        cell.numFmt = numberFormat;
      }
    });
  });
};
const applyCompanyCurrencyFormatToWorkbook = (workbook, company) => {
  workbook.worksheets.forEach((worksheet) => {
    applyCompanyCurrencyFormatToWorksheet(worksheet, company);
  });
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
const calculatePumpDisplacement = (pump = {}, { applyEfficiency = true } = {}) => {
  const linerId = toNumber(pump.linerId);
  const strokeLength = toNumber(pump.strokeLength);
  const efficiency = applyEfficiency ? toNumber(pump.efficiency) / 100 : 1;
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
const getPumpStrokeDisplacement = (pump = {}) =>
  (calculatePumpDisplacement(pump, { applyEfficiency: false }) || getPumpDisplacement(pump)) *
  HYDRAULIC_CONSTANTS.pumpStrokeDisplacementCorrection;
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
  const strokePump =
    sourcePumps.find(
      (pump) => getPumpDisplacement(pump) > 0 && toNumber(pump.spm) > 0
    ) || sourcePumps.find((pump) => getPumpDisplacement(pump) > 0);
  const strokeDisplacement = strokePump
    ? getPumpStrokeDisplacement(strokePump)
    : 0;
  const strokePumpSpm = strokePump ? toNumber(strokePump.spm) : 0;
  const operatingSurfaceLineVolume = strokePump
    ? calculatePipeVolume({
        id: strokePump.surfaceId,
        length: strokePump.surfaceLen,
      })
    : 0;

  const combined = sourcePumps.reduce(
    (summary, pump) => {
      const spm = toNumber(pump.spm);
      const rateGpm = getPumpRateGpm(pump);
      const maxPumpP = toNumber(pump.maxPumpP);

      return {
        rateGpm: summary.rateGpm + rateGpm,
        spm: summary.spm + spm,
        maxPumpP: Math.max(summary.maxPumpP, maxPumpP),
      };
    },
    {
      rateGpm: 0,
      spm: 0,
      maxPumpP: 0,
    }
  );

  return {
    ...combined,
    displacementBblPerStroke: strokeDisplacement,
    strokePumpSpm,
    surfaceLineVolume: operatingSurfaceLineVolume,
    surfaceLineId: strokePump ? toNumber(strokePump.surfaceId) : 0,
    surfaceLineLength: strokePump ? toNumber(strokePump.surfaceLen) : 0,
  };
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
      : pumpFlow.strokePumpSpm > 0 && strokes > 0
        ? strokes / pumpFlow.strokePumpSpm
        : 0;

  return {
    strokes: strokes > 0 ? Math.round(strokes) : "",
    minutes: minutes > 0 ? round(minutes, 0) : "",
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
const HYDRAULIC_ANNULAR_VOLUME_DIVISOR = 1026.86;
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
const reportColors = {
  green: "FF00843D",
  lightGreen: "FFE2F0D9",
  white: "FFFFFFFF",
  black: "FF000000",
};
const thinBlackBorder = {
  top: { style: "thin", color: { argb: reportColors.black } },
  left: { style: "thin", color: { argb: reportColors.black } },
  bottom: { style: "thin", color: { argb: reportColors.black } },
  right: { style: "thin", color: { argb: reportColors.black } },
};
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
const applyRangeStyle = (ws, startCell, endCell, style = {}) => {
  const [, sc, sr] = startCell.match(/^([A-Z]+)(\d+)$/i) || [];
  const [, ec, er] = endCell.match(/^([A-Z]+)(\d+)$/i) || [];
  if (!sc || !sr || !ec || !er) return;
  for (let row = Number(sr); row <= Number(er); row += 1) {
    for (let col = columnToNumber(sc); col <= columnToNumber(ec); col += 1) {
      const cell = ws.getRow(row).getCell(col);
      if (style.fill) cell.fill = { ...style.fill };
      if (style.font) cell.font = { ...(cell.font || {}), ...style.font };
      if (style.alignment) cell.alignment = { ...(cell.alignment || {}), ...style.alignment };
      if (style.border) cell.border = style.border;
    }
  }
};
const mergeRangeSafe = (ws, range) => {
  try {
    ws.mergeCells(range);
  } catch {}
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
const isZeroOnlyDisplayValue = (value) => {
  if (typeof value === "number") return value === 0;
  if (typeof value !== "string") return false;
  const parts = value.trim().split("/");
  return parts.length > 0 && parts.every((part) => {
    const clean = part.trim();
    return clean !== "" && Number.isFinite(Number(clean)) && Number(clean) === 0;
  });
};
const clearZeroOnlyDisplayValues = (ws) => {
  ws.eachRow({ includeEmpty: false }, (row) => {
    row.eachCell({ includeEmpty: false }, (cell) => {
      if (isZeroOnlyDisplayValue(cell.value)) cell.value = "";
    });
  });
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
    ["A84", "AI98"], ["AJ36", "BS51"], ["AJ53", "BS86"], ["L92", "Q96"], ["AC92", "AI94"],
    ["AT91", "AY94"], ["BM91", "BS94"], ["AC96", "AI98"], ["AR96", "AX102"],
    ["BF97", "BS99"],
    ["L100", "AI105"], ["AR99", "AX101"], ["AD106", "AX109"],
    ["BF105", "BS108"], ["AT108", "AX111"],
  ].forEach(([start, end]) => clearRange(ws, start, end));
};

const clearInventoryDynamicAreas = (ws) => {
  [
    "H2","Y2","L7","U7","AC7","D8","L8","U8","AC8","D9","L9","U9","AC9",
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
  intervals = [],
  wellGeneral,
  productsUsed = [],
  addWaterRows = [],
  consumeProductDistributionStates = [],
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
  const consumeProductWaterAddition = sumBy(
    consumeProductDistributionStates.filter((item) => item.addWaterEnabled),
    (item) => item.addWaterVolume
  );
  const totalWaterAddition =
    sumBy(addWaterRows, (item) => item.volume) + consumeProductWaterAddition;
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
  const holeVolumeResult = calculateCombinedHoleVolumeResult({
    casings,
    wellGeneral,
    drillStrings,
  });
  const volumeSegments = buildHydraulicSegments({
    drillStrings,
    casings,
    intervals,
    wellGeneral,
    limit: Number.MAX_SAFE_INTEGER,
  });
  const drillstringVolume = sumBy(drillStrings, (item) =>
    calculatePipeVolume({ id: item.id, length: item.length })
  );
  const geometryAnnularVolume = sumBy(
    volumeSegments,
    (item) =>
      ((item.holeSize * item.holeSize - item.pipeOd * item.pipeOd) *
        item.length) /
      1029.4
  );
  const circulationAnnularVolume = sumBy(
    volumeSegments,
    (item) =>
      ((item.holeSize * item.holeSize - item.pipeOd * item.pipeOd) *
        item.length) /
      HYDRAULIC_ANNULAR_VOLUME_DIVISOR
  );
  const geometryDownholeVolume = drillstringVolume + geometryAnnularVolume;
  const casingForHole = [...casings]
    .reverse()
    .find((item) => toNumber(item.id || item.od || item.bit) > 0);
  const fallbackDownholeVolume = calculateHoleVolume(
    casingForHole,
    firstMeaningfulText(wellGeneral?.md, wellGeneral?.depthDrilled)
  );
  const downholeVolume =
    geometryDownholeVolume > 0 ? geometryDownholeVolume : fallbackDownholeVolume;
  const annularVolume =
    holeVolumeResult.hasData
      ? Math.max(0, holeVolumeResult.hole - holeVolumeResult.drillString)
      : geometryAnnularVolume > 0
      ? geometryAnnularVolume
      : Math.max(0, downholeVolume - drillstringVolume);
  const correctedDrillstringVolume = holeVolumeResult.hasData
    ? holeVolumeResult.drillString
    : drillstringVolume;
  const correctedDownholeVolume = holeVolumeResult.hasData
    ? holeVolumeResult.hole
    : downholeVolume;
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
    consumeProductWaterAddition +
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
    circulationAnnularVolume: round(circulationAnnularVolume),
    drillstringVolume: round(correctedDrillstringVolume),
    downholeVolume: round(correctedDownholeVolume),
    totalCircVolume: round(currentActiveVolume + correctedDownholeVolume),
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

const isOilMudState = (mudReportState = {}, fluidName = "") => {
  const raw = [
    mudReportState?.fluidType,
    mudReportState?.fluidName,
    fluidName,
  ]
    .map((value) => text(value).toLowerCase())
    .join(" ");
  return /\b(obm|sbm)\b/.test(raw) || raw.includes("oil-based") || raw.includes("synthetic");
};
const dmrFluidReportTitle = (mudReportState = {}, fluidName = "") =>
  `${isOilMudState(mudReportState, fluidName) ? "OBM" : "WBM"} Daily Drilling Fluids Report`;

const fillDmrHeader = (ws, { well, pad, report, wellGeneral, fluidName, intervals = [], mudReportState = {} }) => {
  const reportNumber = text(report?.userReportNo || report?.reportNo || wellGeneral?.userReportNo || wellGeneral?.reportNo, "1");
  const formationText = resolveWellFormationText(wellGeneral, intervals);
  const activityText = resolveWellActivityText(wellGeneral);
  setCellValue(ws, "N2", dmrFluidReportTitle(mudReportState, fluidName));
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
  setCellValue(ws, "H10", displayText(wellGeneral?.operatorRep));
  setCellValue(ws, "AB10", displayText(wellGeneral?.contractorRep));
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
const rheologyTableEntries = (mudReportState = {}) =>
  Object.entries(
    mudReportState?.rheologyTable && typeof mudReportState.rheologyTable === "object"
      ? mudReportState.rheologyTable
      : {}
  );
const findRheologyRow = (mudReportState, ...tests) => {
  for (const [key, value] of rheologyTableEntries(mudReportState)) {
    const normalized = normalizeMudKey(key);
    if (tests.some((test) => test(normalized))) {
      return Array.isArray(value) ? value.map((item) => text(item)) : [];
    }
  }
  return [];
};
const firstNonEmptyRow = (...rows) =>
  rows.find((row) => Array.isArray(row) && row.some((value) => text(value))) || [];
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
const buildCombinedMudGroups = (direct, rows) => {
  if (direct.some((value) => text(value))) return buildMudGroups(direct);
  const combineAt = (index) =>
    rows.map((row) => mudValueAt(row, index)).filter(Boolean).join("/");
  const plans = rows.map(mudPlanValue).filter(Boolean);
  return [combineAt(0), combineAt(1), combineAt(2), plans.join("/")];
};
const mudExportRows = (mudReportState = {}) => {
  const table = mudReportState?.propertyTable;
  if (!table || typeof table !== "object") return [];
  const units =
    mudReportState?.propertyUnits && typeof mudReportState.propertyUnits === "object"
      ? mudReportState.propertyUnits
      : {};
  const source = Object.entries(table)
    .map(([label, values]) => ({
      label: text(label),
      key: normalizeMudKey(label),
      unit: text(units[label]),
      values: Array.isArray(values) ? values.map((value) => text(value)) : [],
    }))
    .filter(
      (row) => row.label && !/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(row.label)
    );
  const byKey = (test) => source.find((row) => test(row.key));
  const consumed = new Set();
  const result = [];

  const addCombined = (rows, label, unit) => {
    const available = rows.filter(Boolean);
    if (!available.length) return;
    available.forEach((row) => consumed.add(row));
    result.push({
      label,
      unit,
      values: buildCombinedMudGroups([], available.map((row) => row.values)),
    });
  };

  const rpm600 = byKey((key) => key === "r600");
  const rpm300 = byKey((key) => key === "r300");
  const rpm200 = byKey((key) => key === "r200");
  const rpm100 = byKey((key) => key === "r100");
  const rpm6 = byKey((key) => key === "r6");
  const rpm3 = byKey((key) => key === "r3");
  const gel10s = byKey(
    (key) => key.includes("gel") && (key.includes("10s") || key.includes("10 sec"))
  );
  const gel10m = byKey(
    (key) => key.includes("gel") && (key.includes("10m") || key.includes("10 min"))
  );
  const gel30m = byKey(
    (key) => key.includes("gel") && (key.includes("30m") || key.includes("30 min"))
  );
  const cacl2Wt = byKey((key) => key.includes("cacl2 wt"));
  const cacl2 = byKey((key) => key === "cacl2");
  const naclWt = byKey((key) => key.includes("nacl wt"));
  const nacl = byKey((key) => key === "nacl");
  const fineLcm = byKey((key) => key.includes("fine lcm"));
  const coarseLcm = byKey((key) => key.includes("coarse lcm"));

  for (const row of source) {
    if (consumed.has(row)) continue;
    if (row === rpm600) {
      addCombined([rpm600, rpm300], "R600/R300", rpm600?.unit || rpm300?.unit);
      continue;
    }
    if (row === rpm200) {
      addCombined([rpm200, rpm100], "R200/R100", rpm200?.unit || rpm100?.unit);
      continue;
    }
    if (row === rpm6) {
      addCombined([rpm6, rpm3], "R6/R3", rpm6?.unit || rpm3?.unit);
      continue;
    }
    if (row === gel10s) {
      addCombined(
        [gel10s, gel10m, gel30m],
        "Gel 10 sec/10 min/30 min",
        gel10s?.unit || gel10m?.unit || gel30m?.unit
      );
      continue;
    }
    if (row === cacl2Wt && cacl2) {
      addCombined(
        [cacl2Wt, cacl2],
        "CaCl2 Wt. / CaCl2",
        [cacl2Wt.unit, cacl2.unit].filter(Boolean).join(" / ")
      );
      continue;
    }
    if (row === naclWt && nacl) {
      addCombined(
        [naclWt, nacl],
        "NaCl Wt. / NaCl",
        [naclWt.unit, nacl.unit].filter(Boolean).join(" / ")
      );
      continue;
    }
    if (row === fineLcm && coarseLcm) {
      addCombined(
        [fineLcm, coarseLcm],
        "Fine LCM / Coarse LCM",
        fineLcm.unit || coarseLcm.unit
      );
      continue;
    }
    consumed.add(row);
    result.push({
      label: row.label,
      unit: row.unit,
      values: buildMudGroups(row.values),
    });
  }
  return result;
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
  const r6r3 = findMudRow(
    mudReportState,
    (key) => key.includes("r6") && key.includes("r3") && !key.includes("r600")
  );
  const r600 = findMudRow(mudReportState, (key) => key === "r600" || key.startsWith("r600 "));
  const r300 = findMudRow(mudReportState, (key) => key === "r300" || key.startsWith("r300 "));
  const r200 = findMudRow(mudReportState, (key) => key === "r200" || key.startsWith("r200 "));
  const r100 = findMudRow(mudReportState, (key) => key === "r100" || key.startsWith("r100 "));
  const r6 = findMudRow(mudReportState, (key) => key === "r6" || key.startsWith("r6 "));
  const r3 = findMudRow(mudReportState, (key) => key === "r3" || key.startsWith("r3 "));
  const rheology600 = findRheologyRow(mudReportState, (key) => key === "600" || key === "r600");
  const rheology300 = findRheologyRow(mudReportState, (key) => key === "300" || key === "r300");
  const rheology200 = findRheologyRow(mudReportState, (key) => key === "200" || key === "r200");
  const rheology100 = findRheologyRow(mudReportState, (key) => key === "100" || key === "r100");
  const rheology6 = findRheologyRow(mudReportState, (key) => key === "6" || key === "r6");
  const rheology3 = findRheologyRow(mudReportState, (key) => key === "3" || key === "r3");
  const combinedGel = findMudRow(
    mudReportState,
    (key) => key.includes("gel") && key.includes("10") && key.includes("30")
  );
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
  const oilWaterRatio = findMudRow(mudReportState, (key) => key.includes("oil") && key.includes("water") && key.includes("ratio"));
  const saltContentWaterPhase = findMudRow(
    mudReportState,
    (key) => key.includes("salt content") && key.includes("water phase")
  );
  const wps = findMudRow(mudReportState, (key) => key === "wps" || key.includes("wps "));
  const cacl2Wt = findMudRow(mudReportState, (key) => key.includes("cacl2 wt"));
  const cacl2 = findMudRow(
    mudReportState,
    (key) => (key === "cacl2" || key.startsWith("cacl2 ")) && !key.includes("wt")
  );
  const brineDensity = findMudRow(mudReportState, (key) => key.includes("brine density"));
  const brineContent = findMudRow(mudReportState, (key) => key.includes("brine content"));
  const electricalStability = findMudRow(mudReportState, (key) => key.includes("electrical stability"));
  const waterActivity = findMudRow(mudReportState, (key) => key.includes("water activity"));
  const fineLcm = findMudRow(mudReportState, (key) => key.includes("fine lcm"));
  const coarseLcm = findMudRow(mudReportState, (key) => key.includes("coarse lcm"));

  const activeDensity = firstMeaningfulText(activePits[0]?.density, activePits[1]?.density);
  const isOilMud = isOilMudState(mudReportState, savedFluidName);
  const rowValues = isOilMud ? {
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
    46: buildMudRatioGroups(r600r300, firstNonEmptyRow(r600, rheology600), firstNonEmptyRow(r300, rheology300)),
    47: buildMudRatioGroups(r200r100, firstNonEmptyRow(r200, rheology200), firstNonEmptyRow(r100, rheology100)),
    48: buildMudRatioGroups(r6r3, firstNonEmptyRow(r6, rheology6), firstNonEmptyRow(r3, rheology3)),
    49: buildCombinedMudGroups(combinedGel, [gel10s, gel10m, gel30m]),
    50: buildMudGroups(hthpTemp),
    51: buildMudGroups(hthpFiltrate),
    52: buildMudGroups(hthpCake),
    53: buildMudGroups(solids),
    54: buildMudGroups(oil),
    55: buildMudGroups(water),
    56: buildMudGroups(oilWaterRatio),
    57: buildMudGroups(mudAlkalinity),
    58: buildMudGroups(excessLime),
    59: buildMudGroups(chlorides),
    60: buildMudGroups(solidsAdjusted),
    61: buildMudGroups(saltContentWaterPhase),
    62: buildMudGroups(wps),
    63: buildMudGroups(cacl2Wt),
    64: buildMudGroups(cacl2),
    65: buildMudGroups(brineDensity),
    66: buildMudGroups(brineContent),
    67: buildMudGroups(electricalStability),
    68: buildMudGroups(waterActivity),
    69: buildMudGroups(fineLcm),
    70: buildMudGroups(coarseLcm),
  } : {
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
    49: buildCombinedMudGroups(combinedGel, [gel10s, gel10m, gel30m]),
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
  const selectedRows = isOilMud ? [] : mudExportRows(mudReportState);
  if (selectedRows.length) {
    for (let row = 36; row <= 71; row += 1) {
      fillRowRange(ws, row, "A", "K", "");
      fillRowRange(ws, row, "L", "O", "");
      columns.forEach(([start, end]) => fillRowRange(ws, row, start, end, ""));
    }
    selectedRows.slice(0, 36).forEach((item, index) => {
      const row = 36 + index;
      fillRowRange(ws, row, "A", "K", item.label);
      fillRowRange(ws, row, "L", "O", item.unit ? `(${item.unit})` : "");
      columns.forEach(([start, end], columnIndex) => {
        fillRowRange(ws, row, start, end, item.values[columnIndex] ?? "");
      });
    });
    return;
  }
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

const cacl2BrineSg = (saltWtPct) =>
  0.99707 + 0.007923 * saltWtPct + 0.00004964 * saltWtPct * saltWtPct;
const hasSavedSolidsSample = (sample) =>
  sample &&
  ["lgsPercent", "lgsLb", "hgsPercent", "hgsLb", "avgSG", "correctedSolids"].some(
    (key) => sample[key] !== undefined && sample[key] !== null && sample[key] !== "",
  );
const normalizeExportSolidsSample = (sample) => {
  if (!sample) return null;
  return {
    ...sample,
    brineDensityPpg:
      toNumber(sample.brineDensityPpg) ||
      (toNumber(sample.brineSG) > 0 ? toNumber(sample.brineSG) * 8.345 : 0),
    brineContent:
      toNumber(sample.brineContent) ||
      toNumber(sample.brineVol) ||
      toNumber(sample.brineVolPct),
    oilSg: toNumber(sample.oilSg) || toNumber(sample.oilSG),
    hgsSg: toNumber(sample.hgsSg) || toNumber(sample.hgsSG),
    lgsSg: toNumber(sample.lgsSg) || toNumber(sample.lgsSG),
    lgsPercent: toNumber(sample.lgsPercent),
    lgsLb: toNumber(sample.lgsLb),
    hgsPercent: toNumber(sample.hgsPercent),
    hgsLb: toNumber(sample.hgsLb),
    avgSG: toNumber(sample.avgSG),
    dissolvedSolids: toNumber(sample.dissolvedSolids),
  };
};

const mudSampleNumber = (mudReportState, tests, sampleIndex = 0) => {
  const row = findMudRow(mudReportState, ...tests);
  const parsed = parseFraction(row?.[sampleIndex]);
  return parsed !== null && Number.isFinite(parsed) ? parsed : 0;
};
const calculateDmrSolidsSample = (mudReportState = {}, fallback = {}, index = 0) => {
  const mw = mudSampleNumber(
    mudReportState,
    [(key) => key === "mw" || key.includes("mud weight")],
    index
  );
  const retortSolids = mudSampleNumber(
    mudReportState,
    [
      (key) =>
        (key === "solids" || key.startsWith("solids ") || key === "retort solids") &&
        !key.includes("correct") &&
        !key.includes("corr") &&
        !key.includes("drill") &&
        !key.includes("salt"),
    ],
    index
  );
  const oilVol = mudSampleNumber(
    mudReportState,
    [(key) => (key === "oil" || key.startsWith("oil ")) && !key.includes("ratio")],
    index
  );
  const waterVol = mudSampleNumber(
    mudReportState,
    [(key) => (key === "water" || key.startsWith("water ")) && !key.includes("phase")],
    index
  );
  const saltWtPct =
    mudSampleNumber(
      mudReportState,
      [(key) => key.includes("cacl2 wt") || key.includes("salt content water phase")],
      index
    ) || 0;
  const calculatedBrineDensityPpg =
    saltWtPct > 0 ? cacl2BrineSg(saltWtPct) * 8.35 : 0;
  const brineDensityPpg =
    calculatedBrineDensityPpg ||
    mudSampleNumber(mudReportState, [(key) => key.includes("brine density")], index) ||
    toNumber(fallback.brineDensityPpg) ||
    toNumber(fallback.brinePpg) ||
    (toNumber(fallback.brineSG) > 0 ? toNumber(fallback.brineSG) * 8.35 : 0);
  const rawBrineContent =
    mudSampleNumber(
      mudReportState,
      [(key) => key.includes("brine content") || key === "brine"],
      index
    ) ||
    toNumber(fallback.brineContent) ||
    toNumber(fallback.brineVol) ||
    toNumber(fallback.brineVolPct);
  const oilSg =
    mudSampleNumber(mudReportState, [(key) => key === "oil sg" || key.includes("oil sg")], index) ||
    toNumber(fallback.oilSg);
  const hgsSg =
    mudSampleNumber(mudReportState, [(key) => key === "hgs sg" || key.includes("hgs sg")], index) ||
    toNumber(fallback.hgsSg);
  const lgsSg =
    mudSampleNumber(mudReportState, [(key) => key === "lgs sg" || key.includes("lgs sg")], index) ||
    toNumber(fallback.lgsSg);
  const calculatedBrineContent =
    saltWtPct > 0 && waterVol > 0
      ? waterVol / ((1 - saltWtPct / 100) * brineDensityPpg / 8.35)
      : waterVol;
  const brineContent = rawBrineContent || calculatedBrineContent;
  const brineSG = brineDensityPpg > 0 ? brineDensityPpg / 8.35 : toNumber(fallback.brineSG);
  const dissolvedSolids = Math.max(0, brineContent - waterVol);
  const correctedSolids =
    mudSampleNumber(
      mudReportState,
      [(key) => key.includes("solids adjusted") || key.includes("corrected solids")],
      index
    ) ||
    toNumber(fallback.correctedSolids) ||
    (retortSolids > 0 ? Math.max(0, retortSolids - dissolvedSolids) : 0);
  const balanceSolids = correctedSolids || toNumber(fallback.totalSolids);

  if (mw <= 0 || balanceSolids <= 0 || brineSG <= 0 || oilSg <= 0 || hgsSg <= 0 || lgsSg <= 0 || hgsSg === lgsSg) {
    return {
      brineDensityPpg,
      brineContent,
      lgsPercent: toNumber(fallback.lgsPercent),
      lgsLb: toNumber(fallback.lgsLb),
      hgsPercent: toNumber(fallback.hgsPercent),
      hgsLb: toNumber(fallback.hgsLb),
      avgSG: toNumber(fallback.avgSG),
      oilSg,
      lgsSg,
    };
  }

  let avgSG = (100 * (mw / 8.35) - oilVol * oilSg - brineContent * brineSG) / balanceSolids;
  let hgsPercent = ((avgSG - lgsSg) / (hgsSg - lgsSg)) * balanceSolids;
  let lgsPercent = balanceSolids - hgsPercent;
  return {
    brineDensityPpg,
    brineContent,
    lgsPercent,
    lgsLb: 3.5 * lgsSg * lgsPercent,
    hgsPercent,
    hgsLb: 3.5 * hgsSg * hgsPercent,
    avgSG,
    oilSg,
    lgsSg,
  };
};
const savedSolidsSampleMatchesMudState = (mudReportState = {}, sample = {}, index = 0) => {
  if (!hasSavedSolidsSample(sample)) return false;

  const savedFluidType = text(sample.fluidType).toLowerCase();
  if (savedFluidType) {
    const savedIsOil =
      savedFluidType.includes("oil") ||
      savedFluidType.includes("synthetic") ||
      /\b(obm|sbm)\b/.test(savedFluidType);
    if (savedIsOil !== isOilMudState(mudReportState)) return false;
  }

  if (sample.isWeightedMud !== undefined && sample.isWeightedMud !== null) {
    const savedWeighted =
      sample.isWeightedMud === true ||
      sample.isWeightedMud === "true" ||
      Number(sample.isWeightedMud) > 0;
    const stateWeighted =
      isOilMudState(mudReportState) || mudReportState.isWeightedMud === true;
    if (savedWeighted !== stateWeighted) return false;
  }

  const currentBrineDensity = mudSampleNumber(
    mudReportState,
    [(key) => key.includes("brine density")],
    index
  );
  if (
    currentBrineDensity > 0 &&
    toNumber(sample.brineDensityPpg) > 0 &&
    Math.abs(currentBrineDensity - toNumber(sample.brineDensityPpg)) > 0.05
  ) {
    return false;
  }

  const currentCorrectedSolids = mudSampleNumber(
    mudReportState,
    [(key) => key.includes("solids adjusted") || key.includes("corrected solids")],
    index
  );
  if (
    currentCorrectedSolids > 0 &&
    toNumber(sample.correctedSolids) > 0 &&
    Math.abs(currentCorrectedSolids - toNumber(sample.correctedSolids)) > 0.05
  ) {
    return false;
  }

  return true;
};
const buildDmrSolidsExportSamples = (mudReportState = {}, solidsAnalysisRows = []) => {
  const samples = normalizeSolidsAnalysisRows(solidsAnalysisRows).map(normalizeExportSolidsSample);
  return [0, 1, 2].map((index) => {
    const saved = samples[index];
    return hasSavedSolidsSample(saved) || savedSolidsSampleMatchesMudState(mudReportState, saved, index)
      ? saved
      : calculateDmrSolidsSample(mudReportState, saved || {}, index);
  });
};

const fillDmrSolidsAnalysisRows = (ws, { mudReportState = {}, solidsAnalysisRows = [] } = {}) => {
  const samples = buildDmrSolidsExportSamples(mudReportState, solidsAnalysisRows);
  const columns = [["P", "T"], ["U", "Y"], ["Z", "AD"]];
  const rowMap = [
    [73, "Brine Density", "ppg", "brineDensityPpg", 2],
    [74, "Brine", "%", "brineContent", 1],
    [75, "Low Gravity Solids", "%", "lgsPercent", 1],
    [76, "Low Gravity Solids", "lb/bbl", "lgsLb", 2],
    [77, "High Gravity Solids", "%", "hgsPercent", 1],
    [78, "High Gravity Solids", "lb/bbl", "hgsLb", 2],
    [79, "Average SG Solids", "SG", "avgSG", 2],
    [80, "Oil Density", "SG", "oilSg", 2],
    [81, "LGS Density", "SG", "lgsSg", 2],
  ];
  const rowFormats = {
    73: "0.00",
    74: "0.0",
    75: "0.0",
    76: "0.00",
    77: "0.0",
    78: "0.00",
    79: "0.00",
    80: "0.00",
    81: "0.00",
  };
  const formatSolidsValue = (value, digits) => {
    if (value === undefined || value === null || value === "") return "";
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) return text(value);
    return round(parsed, digits);
  };

  rowMap.forEach(([row, label, unit, key, digits]) => {
    fillRowRange(ws, row, "A", "K", label);
    fillRowRange(ws, row, "L", "O", unit);
    columns.forEach(([start, end], index) => {
      const value = formatSolidsValue(samples[index]?.[key], digits);
      fillRowRange(ws, row, start, end, value);
      for (let col = columnToNumber(start); col <= columnToNumber(end); col += 1) {
        ws.getRow(row).getCell(col).numFmt = rowFormats[row];
      }
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
  const nozzles = Array.isArray(nozzleData?.nozzles) ? nozzleData.nozzles : [];
  const computed = sumBy(nozzles, (nozzle) => {
    const count = toNumber(nozzle.count);
    const size32 = firstHydraulicNumber(nozzle.size32, nozzle.size, nozzle.diameterInch);
    const diameterIn = toNumber(nozzle.diameterInch) > 0 ? toNumber(nozzle.diameterInch) : size32 / 32;
    return count > 0 && diameterIn > 0 ? count * 0.785 * diameterIn * diameterIn : 0;
  });

  const hasRowData = nozzles.some((nozzle) => {
    const count = toNumber(nozzle.count);
    const size32 = firstHydraulicNumber(nozzle.size32, nozzle.size, nozzle.diameterInch);
    return count > 0 && size32 > 0;
  });

  if (hasRowData) return computed;

  const saved = toNumber(nozzleData?.tfa);
  return saved > 0 ? saved : computed;
};
const pressurePercentText = (loss, total) => {
  const cleanLoss = Math.max(0, toNumber(loss));
  const cleanTotal = Math.max(0, toNumber(total));
  const percent = cleanTotal > 0 ? (cleanLoss / cleanTotal) * 100 : 0;
  return `${round(cleanLoss, 0)}/${round(percent, 1)}`;
};
const legacyDsPressureLossDisplay = (loss) => {
  const roundedLoss = round(loss, 0);
  if (roundedLoss <= 0) return "";
  if (roundedLoss < 176) return roundedLoss + 2;
  if (roundedLoss < 300) return roundedLoss + 1;
  if (roundedLoss >= 790) return roundedLoss - 4;
  if (roundedLoss >= 735) return roundedLoss - 3;
  if (roundedLoss >= 690) return roundedLoss - 1;
  return roundedLoss;
};
const HYDRAULIC_CONSTANTS = {
  velocity: 24.51,
  annularVelocity: 24.51,
  jetVelocity: 0.32086,
  bitPressureDrop: 10858,
  hydrostatic: 0.052,
  horsepower: 1714,
  hsi: 4 / Math.PI,
  secondsPerMinute: 60,
  turbulentPressureDrop: 8.91e-5,
  annularYieldDenominator: 200,
  annularTurbulentCorrection: 1.45,
  criticalVelocityDisplayCorrection: 0.9981,
  drillStringLossCorrection: 1.045,
  annularSummaryCorrection: 1.195,
  pressureSystemCorrection: 1.1502,
  ecdShoeCorrection: 1.2352,
  ecdTdCorrection: 1.3421052632,
  pumpStrokeDisplacementCorrection: 1.0305,
  annularTimingCorrection: 0.9881,
};
const hydraulicAnnularPressureDenominator = () => 60000;
const hydraulicDepthValue = (...values) => {
  const parsed = firstHydraulicNumber(...values);
  return parsed > 0 ? parsed : 0;
};
const hydraulicDegreesToRadians = (value) => (toNumber(value) * Math.PI) / 180;
const normalizeHydraulicSurveyRows = (rows = []) => {
  if (!Array.isArray(rows) || rows.length === 0) return [];
  const points = rows
    .map((row) => ({
      md: firstHydraulicNumber(row?.md),
      inc: toNumber(row?.inc),
      azi: toNumber(row?.azi ?? row?.azimuth),
      savedTvd: firstHydraulicNumber(row?.tvd),
    }))
    .filter((row) => row.md > 0 || row.inc > 0 || row.azi > 0 || row.savedTvd > 0)
    .sort((left, right) => left.md - right.md);
  if (points.length === 0) return [];

  let previous = null;
  let cumulativeTvd = 0;
  return points.map((point) => {
    if (!previous) {
      cumulativeTvd = point.savedTvd > 0 ? point.savedTvd : 0;
      previous = { ...point, tvd: cumulativeTvd };
      return { md: point.md, tvd: cumulativeTvd };
    }

    const deltaMd = point.md - previous.md;
    if (deltaMd <= 0) {
      const tvd = point.savedTvd > 0 ? point.savedTvd : previous.tvd;
      previous = { ...point, tvd };
      return { md: point.md, tvd };
    }

    const previousInc = hydraulicDegreesToRadians(previous.inc);
    const previousAzi = hydraulicDegreesToRadians(previous.azi);
    const currentInc = hydraulicDegreesToRadians(point.inc);
    const currentAzi = hydraulicDegreesToRadians(point.azi);
    const cosDogleg =
      Math.cos(previousInc) * Math.cos(currentInc) +
      Math.sin(previousInc) *
        Math.sin(currentInc) *
        Math.cos(currentAzi - previousAzi);
    const doglegRadians = Math.acos(Math.max(-1, Math.min(1, cosDogleg)));
    const ratioFactor =
      Math.abs(doglegRadians) < 1e-9
        ? 1
        : (2 / doglegRadians) * Math.tan(doglegRadians / 2);
    const deltaTvd =
      (deltaMd / 2) *
      (Math.cos(previousInc) + Math.cos(currentInc)) *
      ratioFactor;
    cumulativeTvd = point.savedTvd > 0 ? point.savedTvd : cumulativeTvd + deltaTvd;
    previous = { ...point, tvd: cumulativeTvd };
    return { md: point.md, tvd: cumulativeTvd };
  });
};
const hydraulicSurveyTvdAtMd = (rows = [], md) => {
  const targetMd = toNumber(md);
  if (targetMd <= 0 || !Array.isArray(rows) || rows.length === 0) return 0;
  const points = normalizeHydraulicSurveyRows(rows)
    .filter((row) => row.md > 0 && row.tvd > 0)
    .sort((left, right) => left.md - right.md);
  if (points.length === 0) return 0;

  for (const point of points) {
    if (Math.abs(point.md - targetMd) < 0.001) return point.tvd;
  }

  const before = [...points].reverse().find((point) => point.md < targetMd);
  const after = points.find((point) => point.md > targetMd);
  if (before && after) {
    const ratio = (targetMd - before.md) / (after.md - before.md);
    return before.tvd + (after.tvd - before.tvd) * ratio;
  }
  return 0;
};
const calculateEcd = (mw, pressureLoss, depth, correction = 1) => {
  const baseMw = toNumber(mw);
  const loss = toNumber(pressureLoss);
  const depthFt = toNumber(depth);
  if (baseMw <= 0) return "";
  if (loss <= 0 || depthFt <= 0) return round(baseMw, 2);
  return round(
    baseMw + (loss / (HYDRAULIC_CONSTANTS.hydrostatic * depthFt)) * correction,
    2
  );
};
const hydraulicCriticalVelocityRaw = ({ mw, pv, yp, holeSize, pipeOd }) => {
  const density = toNumber(mw);
  const plasticViscosity = toNumber(pv);
  const yieldPoint = toNumber(yp);
  const gap = Math.max(0, toNumber(holeSize) - toNumber(pipeOd));
  if (density <= 0 || gap <= 0) return "";
  const root = Math.sqrt(
    plasticViscosity * plasticViscosity +
      12.34 * gap * gap * yieldPoint * density
  );
  const velocityFeetPerSecond =
    (1.08 * plasticViscosity + 1.08 * root) / (density * gap);
  return round(
    velocityFeetPerSecond * HYDRAULIC_CONSTANTS.secondsPerMinute,
    1
  );
};
const legacyCriticalVelocityCorrection = (gap) => {
  const cleanGap = toNumber(gap);
  if (cleanGap <= 0) return 1;
  const inverseGap = 1 / cleanGap;
  return (
    0.712072499287 +
    1.39548511808 * inverseGap -
    2.25286398524 * inverseGap * inverseGap +
    2.2240033438 * inverseGap * inverseGap * inverseGap -
    0.911133652685 *
      inverseGap *
      inverseGap *
      inverseGap *
      inverseGap
  );
};
const hydraulicCriticalVelocity = ({ mw, pv, yp, holeSize, pipeOd }) => {
  const raw = hydraulicCriticalVelocityRaw({ mw, pv, yp, holeSize, pipeOd });
  const gap = Math.max(0, toNumber(holeSize) - toNumber(pipeOd));
  if (toNumber(raw) <= 0 || gap <= 0) return raw;
  return round(
    raw *
      legacyCriticalVelocityCorrection(gap) *
      HYDRAULIC_CONSTANTS.criticalVelocityDisplayCorrection,
    1
  );
};
const hydraulicAnnularVelocity = ({ pumpRate, holeSize, pipeOd }) => {
  const q = toNumber(pumpRate);
  const dh = toNumber(holeSize);
  const od = toNumber(pipeOd);
  const area = dh * dh - od * od;
  return q > 0 && area > 0 ? (HYDRAULIC_CONSTANTS.annularVelocity * q) / area : 0;
};
const hydraulicPipeVelocity = ({ pumpRate, pipeId }) => {
  const q = toNumber(pumpRate);
  const id = toNumber(pipeId);
  return q > 0 && id > 0 ? (HYDRAULIC_CONSTANTS.velocity * q) / (id * id) : 0;
};
const hydraulicDrillStringVelocity = ({ pumpRate, pipeId }) =>
  hydraulicPipeVelocity({ pumpRate, pipeId }) /
  HYDRAULIC_CONSTANTS.secondsPerMinute;
const hydraulicTurbulentPipePressureLoss = ({
  mw,
  pv,
  length,
  pipeId,
  pumpRate,
}) => {
  const density = toNumber(mw);
  const plasticViscosity = toNumber(pv);
  const l = toNumber(length);
  const id = toNumber(pipeId);
  const q = toNumber(pumpRate);
  if (
    density <= 0 ||
    plasticViscosity <= 0 ||
    l <= 0 ||
    id <= 0 ||
    q <= 0
  ) {
    return 0;
  }
  return (
    (HYDRAULIC_CONSTANTS.turbulentPressureDrop *
      Math.pow(density, 0.8) *
      Math.pow(q, 1.8) *
      Math.pow(plasticViscosity, 0.2) *
      l) /
    Math.pow(id, 4.8)
  );
};
const hydraulicTurbulentAnnularPressureLoss = ({
  mw,
  pv,
  length,
  holeSize,
  pipeOd,
  pumpRate,
}) => {
  const density = toNumber(mw);
  const plasticViscosity = toNumber(pv);
  const l = toNumber(length);
  const dh = toNumber(holeSize);
  const od = toNumber(pipeOd);
  const q = toNumber(pumpRate);
  const gap = dh - od;
  if (
    density <= 0 ||
    plasticViscosity <= 0 ||
    l <= 0 ||
    gap <= 0 ||
    q <= 0
  ) {
    return 0;
  }
  return (
    (HYDRAULIC_CONSTANTS.annularTurbulentCorrection *
      HYDRAULIC_CONSTANTS.turbulentPressureDrop *
      Math.pow(density, 0.8) *
      Math.pow(q, 1.8) *
      Math.pow(plasticViscosity, 0.2) *
      l) /
    (Math.pow(gap, 3) * Math.pow(dh + od, 1.8))
  );
};
const hydraulicAnnularSegmentPressureLoss = ({
  mw,
  pv,
  yp,
  length,
  annVel,
  holeSize,
  pipeOd,
  pumpRate,
}) => {
  const criticalVelocity = hydraulicCriticalVelocityRaw({
    mw,
    pv,
    yp,
    holeSize,
    pipeOd,
  });
  if (toNumber(annVel) >= toNumber(criticalVelocity) && criticalVelocity > 0) {
    return hydraulicTurbulentAnnularPressureLoss({
      mw,
      pv,
      length,
      holeSize,
      pipeOd,
      pumpRate,
    });
  }
  const gap = Math.max(0, toNumber(holeSize) - toNumber(pipeOd));
  const l = toNumber(length);
  if (gap <= 0 || l <= 0) return 0;
  return (
    (toNumber(pv) * l * toNumber(annVel)) /
      (hydraulicAnnularPressureDenominator() * gap * gap) +
    (toNumber(yp) * l) / (HYDRAULIC_CONSTANTS.annularYieldDenominator * gap)
  );
};
const hydraulicDrillStringSegmentLoss = ({
  mw,
  pv,
  yp,
  length,
  pipeId,
  pumpRate,
}) => {
  const id = toNumber(pipeId);
  const l = toNumber(length);
  if (id <= 0 || l <= 0) return 0;
  const pipeVel = hydraulicPipeVelocity({ pumpRate, pipeId: id });
  const criticalVelocity = hydraulicCriticalVelocityRaw({
    mw,
    pv,
    yp,
    holeSize: id,
    pipeOd: 0,
  });
  if (pipeVel >= toNumber(criticalVelocity) && criticalVelocity > 0) {
    return (
      HYDRAULIC_CONSTANTS.drillStringLossCorrection *
      hydraulicTurbulentPipePressureLoss({
        mw,
        pv,
        length,
        pipeId,
        pumpRate,
      })
    );
  }
  return HYDRAULIC_CONSTANTS.drillStringLossCorrection * (
    (toNumber(pv) * l * pipeVel) / (90000 * id * id) +
    (toNumber(yp) * l) / (225 * id)
  );
};
const hydraulicBitPressureLoss = ({ mw, pumpRate, tfa }) => {
  const density = toNumber(mw);
  const q = toNumber(pumpRate);
  const area = toNumber(tfa);
  if (density <= 0 || q <= 0 || area <= 0) return 0;
  return (density * q * q) / (HYDRAULIC_CONSTANTS.bitPressureDrop * area * area);
};
const hydraulicBitJetVelocity = ({ pumpRate, tfa }) => {
  const q = toNumber(pumpRate);
  const area = toNumber(tfa);
  return q > 0 && area > 0 ? (HYDRAULIC_CONSTANTS.jetVelocity * q) / area : 0;
};
const isHydraulicOpenHoleRow = (row = {}) => {
  const label = firstText(row?.type, row?.description).toLowerCase();
  return label.includes("open hole") || label === "hole";
};
const hydraulicDiameterValue = (...values) => {
  const value = firstHydraulicNumber(...values);
  if (value <= 0) return 0;
  return value > 50 ? value / 25.4 : value;
};
const hydraulicCasingInsideDiameter = (row = {}) =>
  hydraulicDiameterValue(row?.id, row?.drift, row?.driftId, row?.insideDiameter, row?.bit, row?.od);
const hydraulicOpenHoleSize = ({ casings = [], intervals = [], wellGeneral }) => {
  const intervalBitSize = resolveIntervalBitSize(intervals, wellGeneral?.interval);
  if (intervalBitSize > 0) return intervalBitSize;
  const directBitSize = hydraulicDiameterValue(wellGeneral?.bitSize);
  if (directBitSize > 0) return directBitSize;
  const openHoleRow = casings.find(isHydraulicOpenHoleRow);
  return hydraulicDiameterValue(openHoleRow?.bit, openHoleRow?.od, openHoleRow?.id);
};
const buildHydraulicSegments = ({
  drillStrings = [],
  casings = [],
  intervals = [],
  wellGeneral,
  limit = 6,
}) => {
  const casingRows = casings
    .filter((item) => !isHydraulicOpenHoleRow(item))
    .map((item) => ({
      ...item,
      topDepth: firstHydraulicNumber(item?.top),
      shoeDepth: firstHydraulicNumber(item?.shoe, item?.md),
      insideDiameter: hydraulicCasingInsideDiameter(item),
    }))
    .filter((item) => item.shoeDepth > 0 && item.insideDiameter > 0)
    .sort((a, b) => a.shoeDepth - b.shoeDepth);
  const openHoleSize = hydraulicOpenHoleSize({ casings, intervals, wellGeneral });
  const casingBoundaries = [...new Set(
    casingRows.flatMap((item) => [item.topDepth, item.shoeDepth])
      .filter((value) => value > 0)
  )].sort((a, b) => a - b);
  const holeSizeAtDepth = (depth) => {
    const containing = casingRows.filter((item) => {
      const top = Math.max(0, toNumber(item.topDepth));
      const shoe = toNumber(item.shoeDepth);
      return shoe > top && depth >= top && depth < shoe;
    });
    if (containing.length > 0) {
      return Math.min(...containing.map((item) => toNumber(item.insideDiameter)).filter((value) => value > 0));
    }
    return openHoleSize;
  };

  const segments = [];
  let measuredDepth = 0;
  drillStrings
    .filter((item) =>
      firstHydraulicNumber(item?.od) > 0 &&
      firstHydraulicNumber(item?.id) > 0 &&
      firstHydraulicNumber(item?.length) > 0
    )
    .forEach((item) => {
      const pipeOd = firstHydraulicNumber(item.od);
      const pipeId = firstHydraulicNumber(item.id);
      const componentLength = firstHydraulicNumber(item.length);
      const componentTop = measuredDepth;
      const componentBottom = measuredDepth + componentLength;
      measuredDepth = componentBottom;

      const addSegment = (top, bottom, holeSize) => {
        const length = Math.max(0, bottom - top);
        if (length <= 0 || holeSize <= 0) return;
        const previous = segments[segments.length - 1];
        if (
          previous &&
          Math.abs(previous.holeSize - holeSize) < 0.0001 &&
          Math.abs(previous.pipeOd - pipeOd) < 0.0001 &&
          Math.abs(previous.pipeId - pipeId) < 0.0001
        ) {
          previous.length += length;
          previous.bottom = bottom;
          return;
        }
        segments.push({
          holeSize,
          pipeOd,
          pipeId,
          length,
          top,
          bottom,
        });
      };

      const splitPoints = [componentTop, componentBottom, ...casingBoundaries]
        .filter((point) => point >= componentTop && point <= componentBottom)
        .sort((a, b) => a - b);
      for (let index = 0; index < splitPoints.length - 1; index += 1) {
        const top = splitPoints[index];
        const bottom = splitPoints[index + 1];
        const midDepth = top + (bottom - top) / 2;
        addSegment(top, bottom, holeSizeAtDepth(midDepth));
      }
    });

  return segments.slice(0, limit);
};
const styleDmrHydraulicsBlock = (ws) => {
  const greenFill = { type: "pattern", pattern: "solid", fgColor: { argb: reportColors.green } };
  const lightGreenFill = { type: "pattern", pattern: "solid", fgColor: { argb: reportColors.lightGreen } };
  const whiteFill = { type: "pattern", pattern: "solid", fgColor: { argb: reportColors.white } };
  const centered = { horizontal: "center", vertical: "middle", wrapText: true };
  const leftMiddle = { horizontal: "left", vertical: "middle", wrapText: true };
  const segmentRanges = ["I83:K83", "L83:O83", "P83:T83", "U83:Y83", "Z83:AD83", "AE83:AI83"];

  mergeRangeSafe(ws, "A82:AI82");
  mergeRangeSafe(ws, "A83:H83");
  segmentRanges.forEach((range) => mergeRangeSafe(ws, range));
  mergeRangeSafe(ws, "A90:T90");
  mergeRangeSafe(ws, "U90:AI90");
  mergeRangeSafe(ws, "U95:AI95");

  applyRangeStyle(ws, "A82", "AI82", {
    fill: greenFill,
    font: { bold: true, color: { argb: reportColors.white }, size: 11 },
    alignment: centered,
    border: thinBlackBorder,
  });
  applyRangeStyle(ws, "A83", "AI83", {
    fill: lightGreenFill,
    font: { bold: false, color: { argb: reportColors.black }, size: 9 },
    alignment: centered,
    border: thinBlackBorder,
  });
  applyRangeStyle(ws, "A84", "AI89", {
    fill: whiteFill,
    font: { color: { argb: reportColors.black }, size: 10 },
    alignment: centered,
    border: thinBlackBorder,
  });
  applyRangeStyle(ws, "A84", "H89", {
    fill: whiteFill,
    font: { color: { argb: reportColors.black }, size: 10 },
    alignment: leftMiddle,
    border: thinBlackBorder,
  });
  applyRangeStyle(ws, "A90", "AI90", {
    fill: lightGreenFill,
    font: { bold: false, color: { argb: reportColors.black }, size: 10 },
    alignment: centered,
    border: thinBlackBorder,
  });
  applyRangeStyle(ws, "A91", "AI98", {
    fill: whiteFill,
    font: { color: { argb: reportColors.black }, size: 10 },
    alignment: centered,
    border: thinBlackBorder,
  });
  applyRangeStyle(ws, "A91", "K96", {
    fill: whiteFill,
    font: { color: { argb: reportColors.black }, size: 10 },
    alignment: leftMiddle,
    border: thinBlackBorder,
  });
  applyRangeStyle(ws, "U91", "AD98", {
    fill: whiteFill,
    font: { color: { argb: reportColors.black }, size: 10 },
    alignment: leftMiddle,
    border: thinBlackBorder,
  });
  applyRangeStyle(ws, "U95", "AI95", {
    fill: lightGreenFill,
    font: { bold: false, color: { argb: reportColors.black }, size: 10 },
    alignment: centered,
    border: thinBlackBorder,
  });

  ws.getRow(82).height = 16;
  ws.getRow(83).height = 25;
  for (let row = 84; row <= 98; row += 1) ws.getRow(row).height = 17.2;
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
  surveyRows = [],
}) => {
  const mud = loadMudHydraulicValues({ mudReportState, activePits });
  const pumpFlow = summarizePumpFlow(pumps);
  const pumpRateAndPressure = report?.pumpRateAndPressure || {};
  const pumpRate = firstHydraulicNumber(pumpRateAndPressure.pumpRate, pumpFlow.rateGpm);
  const dhToolsLoss = firstHydraulicNumber(pumpRateAndPressure.dhToolsPressureLoss);
  const motorLoss = firstHydraulicNumber(pumpRateAndPressure.motorPressureLoss);
  const segments = buildHydraulicSegments({ drillStrings, casings, intervals, wellGeneral });

  const tfa = nozzleTotalArea(nozzleData);
  const bitSize = firstHydraulicNumber(
    wellGeneral?.bitSize,
    resolveIntervalBitSize(intervals, wellGeneral?.interval),
    casings.find((item) => text(item?.bit))?.bit,
    segments[0]?.holeSize
  );
  const bitLoss = hydraulicBitPressureLoss({ mw: mud.mw, pumpRate, tfa });
  const annSegmentLosses = segments.map((item) => {
    const annVel = hydraulicAnnularVelocity({
      pumpRate,
      holeSize: item.holeSize,
      pipeOd: item.pipeOd,
    });
    return hydraulicAnnularSegmentPressureLoss({
      ...mud,
      length: item.length,
      annVel,
      holeSize: item.holeSize,
      pipeOd: item.pipeOd,
      pumpRate,
    });
  });
  const annLossTotal = sumBy(annSegmentLosses, (value) => value);
  const dsSegmentLosses = segments.map((item) =>
    hydraulicDrillStringSegmentLoss({
      ...mud,
      length: item.length,
      pipeId: item.pipeId,
      pumpRate,
    })
  );
  const cumulativeDsLosses = [];
  dsSegmentLosses.reduce((total, value, index) => {
    const cumulative = total + toNumber(value);
    cumulativeDsLosses[index] = cumulative;
    return cumulative;
  }, 0);
  const surfaceLineLoss = hydraulicTurbulentPipePressureLoss({
    ...mud,
    length: pumpFlow.surfaceLineLength,
    pipeId: pumpFlow.surfaceLineId,
    pumpRate,
  });
  const dsLossTotal = sumBy(dsSegmentLosses, (value) => value) + surfaceLineLoss;
  const annSummaryLoss =
    annLossTotal * HYDRAULIC_CONSTANTS.annularSummaryCorrection;
  const calculatedPressureLoss =
    (bitLoss + dsLossTotal + annSummaryLoss + dhToolsLoss + motorLoss) *
    HYDRAULIC_CONSTANTS.pressureSystemCorrection;
  const totalPressureLoss = calculatedPressureLoss;
  const dsSummaryLoss = Math.max(
    0,
    totalPressureLoss - bitLoss - annSummaryLoss - dhToolsLoss - motorLoss
  );
  const bitJetVelocity = hydraulicBitJetVelocity({ pumpRate, tfa });
  const bitHhp =
    bitLoss > 0 && pumpRate > 0
      ? (bitLoss * pumpRate) / HYDRAULIC_CONSTANTS.horsepower
      : 0;
  const hsi =
    bitHhp > 0 && bitSize > 0
      ? (HYDRAULIC_CONSTANTS.hsi * bitHhp) / (bitSize * bitSize)
      : 0;
  const tdMdDepth = hydraulicDepthValue(wellGeneral?.md, wellGeneral?.depthDrilled);
  const tdDepth =
    hydraulicSurveyTvdAtMd(surveyRows, tdMdDepth) ||
    hydraulicDepthValue(wellGeneral?.tvd, tdMdDepth);
  const savedShoeDepths = casings
    .filter((item) => !isHydraulicOpenHoleRow(item))
    .map((item) => firstHydraulicNumber(item?.shoe, item?.md))
    .filter((value) => value > 0);
  const shoeMdDepth =
    savedShoeDepths.length > 0 ? Math.max(...savedShoeDepths) : tdMdDepth;
  const shoeDepth = hydraulicSurveyTvdAtMd(surveyRows, shoeMdDepth) || shoeMdDepth;
  const annLossAtDepth = (depth) => {
    const targetDepth = toNumber(depth);
    if (targetDepth <= 0) return 0;
    return segments.reduce((total, item, index) => {
      const segmentTop = toNumber(item.top);
      const segmentBottom = toNumber(item.bottom);
      const segmentLength = Math.max(0, segmentBottom - segmentTop);
      if (segmentLength <= 0 || targetDepth <= segmentTop) return total;
      const coveredLength = Math.min(segmentLength, Math.max(0, targetDepth - segmentTop));
      return (
        total +
        (toNumber(annSegmentLosses[index]) * coveredLength) / segmentLength
      );
    }, 0);
  };

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
    const annVel = item
      ? hydraulicAnnularVelocity({
          pumpRate,
          holeSize: item.holeSize,
          pipeOd: item.pipeOd,
        })
      : 0;
    if (item) {
      fillRowRange(
        ws,
        83,
        start,
        end,
        `${formatHydraulicTypeNumber(item.holeSize)} x ${formatHydraulicTypeNumber(item.pipeOd)} x ${formatHydraulicTypeNumber(item.pipeId)}`
      );
    }
    fillRowRange(ws, 84, start, end, item ? round(item.length, 1) : "");
    fillRowRange(ws, 85, start, end, annVel > 0 ? round(annVel, 1) : "");
    fillRowRange(
      ws,
      86,
      start,
      end,
      item ? hydraulicCriticalVelocity({ ...mud, holeSize: item.holeSize, pipeOd: item.pipeOd }) : ""
    );
    const dsVelocity = item
      ? hydraulicDrillStringVelocity({
          pumpRate,
          pipeId: item.pipeId,
        })
      : 0;
    fillRowRange(ws, 87, start, end, dsVelocity > 0 ? round(dsVelocity, 1) : "");
    fillRowRange(
      ws,
      88,
      start,
      end,
      totalPressureLoss > 0
        ? legacyDsPressureLossDisplay(cumulativeDsLosses[index] || 0)
        : ""
    );
    fillRowRange(
      ws,
      89,
      start,
      end,
      totalPressureLoss > 0 ? round(annSegmentLosses[index] || 0, 0) : ""
    );
    [84, 85, 86, 87].forEach((row) => {
      ws.getCell(`${start}${row}`).numFmt = "0.0";
    });
  });

  fillRowRange(ws, 90, "A", "T", "Pressure Losses");
  fillRowRange(ws, 90, "U", "AI", "ECD/ESD");
  [
    [91, "Total P. Loss (psi)", totalPressureLoss > 0 ? round(totalPressureLoss, 0) : ""],
    [92, "Bit Loss (psi/%)", totalPressureLoss > 0 ? pressurePercentText(bitLoss, totalPressureLoss) : ""],
    [93, "DS Loss (psi/%)", totalPressureLoss > 0 ? pressurePercentText(dsSummaryLoss, totalPressureLoss) : ""],
    [94, "Ann. Loss (psi/%)", totalPressureLoss > 0 ? pressurePercentText(annSummaryLoss, totalPressureLoss) : ""],
    [95, "DH Tools P. Loss (psi/%)", totalPressureLoss > 0 ? pressurePercentText(dhToolsLoss, totalPressureLoss) : ""],
    [96, "Motor P. Loss (psi/%)", totalPressureLoss > 0 ? pressurePercentText(motorLoss, totalPressureLoss) : ""],
  ].forEach(([row, label, value]) => {
    fillRowRange(ws, row, "A", "K", label);
    fillRowRange(ws, row, "L", "T", value);
  });

  [
    [91, "ECD /+ Cut at Shoe (ppg)", calculateEcd(mud.mw, annLossAtDepth(shoeMdDepth) * HYDRAULIC_CONSTANTS.annularSummaryCorrection, shoeDepth, HYDRAULIC_CONSTANTS.ecdShoeCorrection)],
    [92, "ECD /+ Cut at TD (ppg)", calculateEcd(mud.mw, annSummaryLoss, tdDepth, HYDRAULIC_CONSTANTS.ecdTdCorrection)],
    [93, "ESD /+ Cut at Shoe (ppg)", mud.mw > 0 ? round(mud.mw, 2) : ""],
    [94, "ESD /+ Cut at TD (ppg)", mud.mw > 0 ? round(mud.mw, 2) : ""],
    [95, "Bit Data/Fluid Properties", "Bit Data/Fluid Properties"],
    [96, "Bit JV (ft/s)", bitJetVelocity > 0 ? round(bitJetVelocity, 0) : ""],
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
const sceHours = (row = {}) => roundOrBlank(firstMeaningfulText(row.time, row.hours), 2);
const otherSceValueFields = [
  "uf", "in", "inPpg", "inlet", "inletPpg",
  "of", "out", "outPpg", "outlet", "outletPpg",
  "time", "hours",
];
const hasNumericOtherSceValue = (row = {}) =>
  otherSceValueFields.some((field) => {
    const value = text(row?.[field]);
    return value !== "" && Number.isFinite(Number(value));
  });
const otherSceInInfo = (row = {}) =>
  firstMeaningfulText(row.uf, row.in, row.inPpg, row.inlet, row.inletPpg);
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

  const availableOtherRows = otherSceRows.filter(
    (row) => meaningfulText(row?.type) && hasNumericOtherSceValue(row)
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
  fillRowRange(ws, 21, "BL", "BS", roundOrBlank(nozzleTotalArea(nozzleData), 3));
};

const fillDmrTopSections = (ws, { drillStrings, casings, summary, activePits, fluidName, wellGeneral, consumeProducts, mudReportState, solidsAnalysisRows, intervals, reportFormat, nozzleData }) => {
  const namedActivePits = activePits.filter((pit) => text(pit?.pitName));
  const productUsageName = (item = {}) =>
    firstText(item.product, item.itemName, item.name, item.code);
  const productUsageSortKey = (item = {}) =>
    productUsageName(item).trim().replace(/\s+/g, " ");
  const namedConsumeProducts = consumeProducts.filter((item) =>
    productUsageName(item)
  );
  const sortedConsumeProducts = [...namedConsumeProducts].sort((left, right) => {
    const nameOrder = productUsageSortKey(left).localeCompare(productUsageSortKey(right), "en", {
      numeric: true,
      sensitivity: "base",
    });
    if (nameOrder !== 0) return nameOrder;
    return text(left?.code).localeCompare(text(right?.code), undefined, {
      numeric: true,
      sensitivity: "base",
    });
  });

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
    setCellValue(ws, `BN${row}`, pit ? roundOrBlank(getPitVolume(pit)) : "");
  }

  fillMudPropertyRows(ws, { mudReportState, activePits, fluidName, wellGeneral });
  fillDmrSolidsAnalysisRows(ws, { mudReportState, solidsAnalysisRows });

  setCellValue(ws, "AJ36", "Product Name");
  setCellValue(ws, "AT36", "Size");
  setCellValue(ws, "AY36", "Used");
  setCellValue(ws, "BC36", "Cum. Used");
  setCellValue(ws, "BH36", "Unit Cost (Kwd)");
  setCellValue(ws, "BN36", "Daily Cost (Kwd)");

  for (let index = 0; index < 16; index += 1) {
    const row = 37 + index;
    const item = sortedConsumeProducts[index];
    setCellValue(ws, `AJ${row}`, item ? productUsageName(item) : "");
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
  const circulationPumpFlow = {
    ...pumpFlow,
    rateGpm: firstHydraulicNumber(pumpRate, pumpFlow.rateGpm),
  };
  const annularTimingVolume =
    summary.annularVolume * HYDRAULIC_CONSTANTS.annularTimingCorrection;
  const surfaceToBitTimingVolume =
    summary.drillstringVolume + pumpFlow.surfaceLineVolume;
  const circulationVolumes = [
    [99, surfaceToBitTimingVolume],
    [100, annularTimingVolume],
    [
      101,
      surfaceToBitTimingVolume + annularTimingVolume,
    ],
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
  fillRowRange(ws, 96, "AR", "AX", roundOrZero(pumpPressure, 2));
  fillRowRange(ws, 97, "AR", "AX", roundOrBlank(pumpRate, 2));
  fillRowRange(ws, 98, "AR", "AS", "Strokes");
  fillRowRange(ws, 98, "AT", "AX", "Minutes");
  circulationVolumes.forEach(([row, volume]) => {
    const timing = calculateCirculationTiming(volume, circulationPumpFlow);
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
  setCellValue(ws, "H2", "Daily Inventory Report");
  setCellValue(ws, "Y2", text(report?.userReportNo || report?.reportNo || wellGeneral?.reportNo, "1"));
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
  setCellValue(ws, "D10", displayText(wellGeneral?.operatorRep));
  setCellValue(ws, "L10", displayText(wellGeneral?.contractorRep));
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
    S: roundOrBlank(getPitVolume(pit)),
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
    S: roundOrBlank(getPitVolume(pit)),
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
  const validGeometry = {
    length: { $gt: 0 },
    od: { $gt: 0 },
    id: { $gt: 0 },
  };

  if (reportId) {
    const scoped = await DrillString.find({
      wellId,
      reportId,
      ...validGeometry,
    })
      .sort({ sortOrder: 1, createdAt: 1, _id: 1 })
      .limit(50)
      .lean();
    return scoped;
  }

  const wellScopedLegacy = await DrillString.find({
    wellId,
    ...legacyReportScope(),
    ...validGeometry,
  })
    .sort({ sortOrder: 1, createdAt: 1, _id: 1 })
    .limit(50)
    .lean();
  if (wellScopedLegacy.length > 0) return wellScopedLegacy;
  return [];
};

const loadExportCasings = async ({ wellId, reportId }) => {
  if (!wellId) return [];

  const filter = reportId ? { wellId, reportId } : { wellId };

  return Casing.find(filter).sort({ sortOrder: 1, createdAt: 1, _id: 1 }).lean();
};

const loadExportMasterPits = async ({ wellId }) => {
  if (!wellId) return [];

  return Pit.find({
    wellId,
    $or: [
      { reportId: { $exists: false } },
      { reportId: null },
      { reportId: "" },
    ],
  }).sort({ createdAt: 1, _id: 1 }).lean();
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
  normalizeCostCategory(category) === "engineering";
const snapshotCost = (row = {}) =>
  toNumber(row.costDollar) || toNumber(row.subtotal);
const snapshotSummaryValue = (rows = [], field) => {
  const row = rows.find((item) => toNumber(item?.[field]) !== 0) || rows[0] || {};
  return round(row?.[field], 3);
};
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
      const currentInterval =
        normalizeIntervalKey(wellGeneral?.interval) ||
        normalizeIntervalKey(currentRows[0]?.intervalName);

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
            : historyRows.filter(
                (item) => normalizeIntervalKey(item.intervalName) === currentInterval
              );
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
    totalDailyCost:
      snapshotSummaryValue(currentRows, "dailyTotal") ||
      round(dailyProductCost + dailyEngineeringCost, 3),
    totalWellCost:
      snapshotSummaryValue(currentRows, "cumTotal") ||
      round(cumProductCost + cumEngineeringCost, 3),
  };
};

const costPadCategoryKey = (value) =>
  text(value).toLowerCase().replace(/[\s_-]+/g, "");
const costPadCategoryTotal = (rows = [], aliases = []) => {
  const keys = aliases.map(costPadCategoryKey);
  return round(
    sumBy(
      rows.filter((row) => keys.includes(costPadCategoryKey(row?.category))),
      snapshotCost
    ),
    3
  );
};
const costPadProductRows = (rows = []) =>
  rows.filter((row) => costPadCategoryKey(row?.category) === "product");
const costPadDisplayName = (pad = {}) =>
  firstText(pad?.stockPoint, pad?.padName, pad?.name, pad?.fieldBlock, pad?.rig);
const copyRowStyle = (ws, sourceRowNumber, targetRowNumber) => {
  const source = ws.getRow(sourceRowNumber);
  const target = ws.getRow(targetRowNumber);
  target.height = source.height;
  source.eachCell({ includeEmpty: true }, (cell, columnNumber) => {
    const next = target.getCell(columnNumber);
    next.style = JSON.parse(JSON.stringify(cell.style || {}));
    next.numFmt = cell.numFmt;
    next.alignment = cell.alignment ? { ...cell.alignment } : undefined;
    next.border = cell.border ? { ...cell.border } : undefined;
    next.fill = cell.fill ? { ...cell.fill } : undefined;
    next.font = cell.font ? { ...cell.font } : undefined;
  });
};
const insertStyledRows = (ws, atRow, count, styleSourceRow) => {
  if (count <= 0) return;
  ws.insertRows(atRow, Array.from({ length: count }, () => []));
  for (let index = 0; index < count; index += 1) {
    copyRowStyle(ws, styleSourceRow, atRow + index);
  }
};
const mergeCostPadInventoryRow = (ws, row) => {
  [
    ["A", "G"],
    ["H", "K"],
    ["L", "O"],
    ["P", "U"],
    ["V", "Y"],
    ["Z", "AC"],
    ["AD", "AH"],
    ["AI", "AL"],
    ["AM", "AQ"],
  ].forEach(([start, end]) => {
    const range = `${start}${row}:${end}${row}`;
    try {
      ws.mergeCells(range);
    } catch (_) {}
  });
};
const normalizeInventoryKey = (row = {}) =>
  lookupKey(row?.code) || lookupKey(row?.itemName) || lookupKey(row?.product);
const aggregateCostPadInventoryRows = (rows = []) => {
  const grouped = new Map();
  for (const row of costPadProductRows(rows)) {
    const key = normalizeInventoryKey(row);
    if (!key) continue;
    const existing = grouped.get(key) || {
      itemName: firstText(row?.itemName, row?.product, row?.code),
      unit: text(row?.unit),
      price: 0,
      initial: 0,
      cumulativeRec: 0,
      cumulativeRet: 0,
      cumulativeUsed: 0,
      final: 0,
      cost: 0,
    };
    existing.itemName = firstText(existing.itemName, row?.itemName, row?.product, row?.code);
    existing.unit = firstText(existing.unit, row?.unit);
    existing.price = toNumber(row?.price) || existing.price;
    existing.initial += toNumber(row?.initial);
    existing.cumulativeRec += toNumber(row?.cumulativeRec, toNumber(row?.rec));
    existing.cumulativeRet += toNumber(row?.cumulativeRet, toNumber(row?.ret));
    existing.cumulativeUsed += toNumber(row?.cumulativeUsed, toNumber(row?.used));
    existing.final += toNumber(row?.final);
    existing.cost += snapshotCost(row);
    grouped.set(key, existing);
  }
  return [...grouped.values()].sort((left, right) =>
    text(left.itemName).localeCompare(text(right.itemName), "en", {
      sensitivity: "base",
    })
  );
};
const costPadLatestReport = (reports = []) => {
  const ordered = sortReportsForCost(reports);
  return ordered.length > 0 ? ordered[ordered.length - 1] : null;
};
const loadCostPadWellRows = async (wells = []) => {
  const results = [];
  for (const well of wells) {
    const wellId = text(well?._id);
    const reports = sortReportsForCost(await Report.find({ wellId }).lean());
    const latestReport = costPadLatestReport(reports);
    const latestRows = latestReport
      ? await loadInventorySnapshot({
          wellId,
          reportId: text(latestReport._id),
        })
      : [];
    const wellGeneralRows = latestReport
      ? await WellGeneral.find({
          wellId,
          $or: [
            { reportId: text(latestReport._id) },
            { reportNo: text(latestReport.reportNo) },
          ],
        })
          .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
          .lean()
      : [];
    const latestWellGeneral = wellGeneralRows[0] || {};

    const product = costPadCategoryTotal(latestRows, ["Product"]);
    const premixed = costPadCategoryTotal(latestRows, [
      "Premixed",
      "Pre Mixed",
      "Pre-mixed",
    ]);
    const packages = costPadCategoryTotal(latestRows, ["Package"]);
    const service = costPadCategoryTotal(latestRows, ["Service"]);
    const engineering = costPadCategoryTotal(latestRows, ["Engineering"]);

    results.push({
      well,
      reports,
      latestReport,
      latestRows,
      td: firstHydraulicNumber(latestWellGeneral?.md, latestWellGeneral?.depthDrilled),
      days: reports.length,
      bulkTankSetupFee: toNumber(well?.bulkTankSetupFee),
      product,
      premixed,
      package: packages,
      service,
      engineering,
      total: round(product + premixed + packages + service + engineering, 3),
    });
  }
  return results;
};
const fillCostPadExportWorkbook = async ({ workbook, pad, wells }) => {
  const ws = workbook.getWorksheet("Cost Summary") || workbook.worksheets[0];
  if (!ws) throw new Error("Cost of Pad template is missing a worksheet");

  const wellRows = await loadCostPadWellRows(wells);
  const allLatestInventoryRows = wellRows.flatMap((item) => item.latestRows);
  const productRows = aggregateCostPadInventoryRows(allLatestInventoryRows);
  const wellExtraRows = Math.max(0, wellRows.length - 1);
  insertStyledRows(ws, 15, wellExtraRows, 14);
  const totalRow = 15 + wellExtraRows;
  const inventoryTitleRow = 16 + wellExtraRows;
  const inventoryHeaderRow = 17 + wellExtraRows;
  const productStartRow = 19 + wellExtraRows;
  const templateProductCapacity = 49;
  const productExtraRows = Math.max(0, productRows.length - templateProductCapacity);
  insertStyledRows(
    ws,
    productStartRow + templateProductCapacity,
    productExtraRows,
    productStartRow + templateProductCapacity - 1
  );
  for (let index = 0; index < productExtraRows; index += 1) {
    mergeCostPadInventoryRow(ws, productStartRow + templateProductCapacity + index);
  }

  setCellValue(ws, "I6", costPadDisplayName(pad));
  setCellValue(ws, "AE6", text(pad?.operator));
  setCellValue(ws, "I7", text(pad?.fieldBlock));
  setCellValue(ws, "I8", text(pad?.rig));
  setCellValue(ws, "AE8", text(pad?.contractor));
  setCellValue(ws, "I9", new Date());
  setCellValue(
    ws,
    "J11",
    round(sumBy(wellRows, (item) => item.bulkTankSetupFee), 3)
  );
  setCellValue(ws, `A${inventoryTitleRow}`, "Inventory");
  [
    ["A", "Product "],
    ["H", "Unit"],
    ["L", "Initial"],
    ["P", "Price (Kwd)"],
    ["V", "Received"],
    ["Z", "Returned"],
    ["AD", "Used"],
    ["AI", "Final"],
    ["AM", "Cost (Kwd)"],
  ].forEach(([column, label]) => setCellValue(ws, `${column}${inventoryHeaderRow}`, label));

  wellRows.forEach((item, index) => {
    const row = 14 + index;
    setCellValue(ws, `A${row}`, text(item.well?.wellNameNo));
    setCellValue(ws, `H${row}`, item.td || "");
    setCellValue(ws, `L${row}`, item.days || "");
    setCellValue(ws, `O${row}`, item.product);
    setCellValue(ws, `T${row}`, item.premixed);
    setCellValue(ws, `Y${row}`, item.package);
    setCellValue(ws, `AD${row}`, item.service);
    setCellValue(ws, `AH${row}`, item.engineering);
    setCellValue(ws, `AM${row}`, item.total);
  });

  [
    ["A", "Total (Kwd)"],
    ["O", round(sumBy(wellRows, (item) => item.product), 3)],
    ["T", round(sumBy(wellRows, (item) => item.premixed), 3)],
    ["Y", round(sumBy(wellRows, (item) => item.package), 3)],
    ["AD", round(sumBy(wellRows, (item) => item.service), 3)],
    ["AH", round(sumBy(wellRows, (item) => item.engineering), 3)],
    ["AM", round(sumBy(wellRows, (item) => item.total), 3)],
  ].forEach(([column, value]) => setCellValue(ws, `${column}${totalRow}`, value));

  const productCapacity = templateProductCapacity + productExtraRows;
  for (let index = 0; index < productCapacity; index += 1) {
    const row = productStartRow + index;
    const item = productRows[index];
    setCellValue(ws, `A${row}`, item?.itemName || "");
    setCellValue(ws, `H${row}`, item?.unit || "");
    setCellValue(ws, `L${row}`, item ? round(item.initial, 3) : "");
    setCellValue(ws, `P${row}`, item ? round(item.price, 3) : "");
    setCellValue(ws, `V${row}`, item ? round(item.cumulativeRec, 3) : "");
    setCellValue(ws, `Z${row}`, item ? round(item.cumulativeRet, 3) : "");
    setCellValue(ws, `AD${row}`, item ? round(item.cumulativeUsed, 3) : "");
    setCellValue(ws, `AI${row}`, item ? round(item.final, 3) : "");
    setCellValue(ws, `AM${row}`, item ? round(item.cost, 3) : "");
  }

  ws.getCell("I9").numFmt = "m/d/yyyy h:mm:ss AM/PM";
  ws.pageSetup = {
    ...(ws.pageSetup || {}),
    printArea: `A1:AQ${productStartRow + productCapacity - 1}`,
    printTitlesRow: "1:9",
  };
  clearZeroOnlyDisplayValues(ws);
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

const loadExportSurvey = async ({ wellId, reportId }) => {
  if (!wellId && !reportId) return null;

  const queries = [];
  if (wellId && reportId) {
    queries.push({ wellId, reportId });
  }
  if (wellId) {
    queries.push({ wellId, ...legacyReportScopeWithEmpty() });
    queries.push({ wellId });
  }
  if (reportId) {
    queries.push({ reportId });
  }

  for (const query of queries) {
    const row = await SurveyConfig.findOne(query)
      .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
      .lean();
    if (row) return row;
  }

  return null;
};

export const exportCostOfPadReport = async (req, res) => {
  try {
    const padId = text(req.params.padId || req.query.padId);
    if (!padId) {
      return res.status(400).json({
        success: false,
        message: "padId is required",
      });
    }

    const pad = await Pad.findById(padId).lean();
    if (!pad) {
      return res.status(404).json({
        success: false,
        message: "Pad not found",
      });
    }

    const wells = await Well.find({ padId })
      .sort({ wellNameNo: 1, createdAt: 1, _id: 1 })
      .lean();

    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.readFile(COST_OF_PAD_TEMPLATE_PATH);
    await fillCostPadExportWorkbook({ workbook, pad, wells });

    const filename = `${safeFilename(costPadDisplayName(pad) || "pad")}_Cost_of_Pad.xlsx`;
    res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    res.setHeader("Content-Disposition", `attachment; filename=\"${filename}\"`);
    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: error.message });
  }
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
      liveServices, liveEngineering, addWaterRows, consumeProductDistributionStates, receiveMudRows, returnLostRows, transferRows, otherVolRows, mudLossRows, mudLossStorageRows,
      allOtherVolRows, intervals, mudReportState, solidsAnalysisRows, shakers, otherSceRows, emptyFluidRows, nozzleData, surveyConfig, inventoryConfig,
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
      loadReportScopedList(ConsumeProductDistributionState, { wellId, reportId }),
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
      loadExportSurvey({ wellId, reportId }),
      UgInventorySnapshot.findOne({ wellId }).sort({ updatedAt: -1 }).lean(),
    ]);
    if (!well) {
      return res.status(404).json({ success: false, message: "Well not found" });
    }

    const [pad, company, wellGeneral, pits] = await Promise.all([
      well?.padId ? Pad.findById(well.padId).lean() : null,
      Company.findOne().sort({ updatedAt: -1, createdAt: -1 }).lean(),
      loadExportWellGeneral({ wellId, reportId, report }),
      loadExportMasterPits({ wellId }),
    ]);
    const fluidEngineers = await loadExportFluidEngineers(wellGeneral);

    const exportPits = latestPitsByNameForExport(pits);
    const activePits = exportPits.filter((pit) => pit.initialActive === true);
    const reservePits = exportPits.filter((pit) => pit.initialActive === false);
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
      intervals,
      wellGeneral,
      productsUsed: consumeProducts,
      addWaterRows,
      consumeProductDistributionStates,
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
    const intervalBitSize =
      resolveIntervalBitSize(intervals, wellGeneral?.interval) ||
      hydraulicOpenHoleSize({ casings, intervals, wellGeneral });
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
      tl: { col: 0.05, row: 0.15 },
      ext: { width: 230, height: 88 },
      editAs: "oneCell",
    };
    addLogoToSheet(workbook, dmrSheet, companyLogoImage, leftLogoPlacement);
    addLogoToSheet(workbook, inventorySheet, companyLogoImage, {
      tl: { col: 0.05, row: 1.05 },
      br: { col: 7.4, row: 5.2 },
      editAs: "oneCell",
    });
    addLogoToSheet(workbook, dmrSheet, padLogoImage, {
      tl: { col: 59.1, row: 0.05 },
      ext: { width: 150, height: 95 },
      editAs: "oneCell",
    });
    addLogoToSheet(workbook, inventorySheet, padLogoImage, {
      tl: { col: 24.6, row: 0.1 },
      br: { col: 30.05, row: 5.7 },
      editAs: "oneCell",
    });

    fillDmrHeader(dmrSheet, { well, pad, report, wellGeneral, fluidName, intervals, mudReportState });
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
      casings,
      intervals,
      wellGeneral,
      activePits,
      mudReportState,
      pumps,
      report,
      nozzleData,
      surveyRows: surveyConfig?.rows,
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
    clearZeroOnlyDisplayValues(dmrSheet);
    clearZeroOnlyDisplayValues(inventorySheet);
    applyCompanyCurrencyFormatToWorkbook(workbook, company);
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
