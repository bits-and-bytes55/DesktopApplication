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
import AddWater from "../../modules/addwater/AddWater.js";
import ReceiveMud from "../../modules/receivemud/ReceiveMud.js";
import ReturnLostMud from "../../modules/returnlostmud/ReturnLostMud.js";
import TransferMud from "../../modules/transfermud/TransferMud.js";
import OtherVolAddition from "../../modules/othervol/OtherVolAddition.js";
import MudLoss from "../../modules/mudloss/MudLoss.js";
import MudLossStorage from "../../modules/mudlossstorage/MudLossStorage.js";
import { Interval } from "../../modules/wellInterval/intervalModel.js";
import { loadMergedPits } from "../../utils/pitReportState.js";

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
const text = (value, fallback = "") => {
  const parsed = value?.toString().trim();
  return parsed ? parsed : fallback;
};
const displayText = (value, fallback = "-") => text(value, fallback);
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
    ["BE14", "BK21"], ["BL14", "BS21"], ["M23", "BS34"], ["P36", "AI54"],
    ["AJ36", "BS51"], ["AJ53", "BS86"], ["L92", "Q96"], ["AC92", "AI94"],
    ["AT93", "AY94"], ["BM93", "BS94"], ["AC96", "AI98"], ["AR96", "AX97"],
    ["BF97", "BS99"],
    ["L100", "AI105"], ["AR99", "AX101"], ["AT108", "AX111"],
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
  activePits,
  productsUsed,
  addWaterRows,
  receiveMudRows,
  transferRows,
  returnLostRows,
  otherVolRows,
  mudLossRows,
  mudLossStorageRows,
}) => {
  const currentActiveVolume = sumBy(activePits, (pit) => getActivePitVolume(pit));
  const totalWaterAddition = sumBy(addWaterRows, (item) => item.volume);
  const totalReceived = sumBy(receiveMudRows, (item) => item.netVolume || item.volume);
  const totalProductAddition = sumBy(productsUsed, (item) => item.volumeBbl);
  const totalOtherAddition = sumBy(otherVolRows, (item) => item.totalVolume);
  const totalTransferOut = sumBy(transferRows, (item) => item.totalTransferVol);
  const totalReturned = sumBy(returnLostRows, (item) => item.volReturned);
  const totalLoss =
    sumBy(mudLossRows, (item) => item.totalLoss) +
    sumBy(mudLossStorageRows, (item) => item.totalLoss);
  const totalAdditions =
    totalWaterAddition + totalReceived + totalProductAddition + totalOtherAddition;
  const totalTransfersOut = totalTransferOut + totalReturned;
  const estimatedStartingVolume = Math.max(
    0,
    currentActiveVolume - totalAdditions + totalTransfersOut + totalLoss
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
    finalActiveVolume: round(currentActiveVolume),
  };
};

const fillDmrHeader = (ws, { well, pad, report, wellGeneral, fluidName }) => {
  setCellValue(ws, "AC7", text(report?._id || well?._id || well?.apiWellNo));
  setCellValue(ws, "AT7", formatDate(report?.reportDate || wellGeneral?.date, getReportDate()));
  setCellValue(ws, "BL7", text(report?.userReportNo || report?.reportNo || wellGeneral?.reportNo, "1"));
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

const fillDmrTopSections = (ws, { drillStrings, casings, summary, activePits, fluidName, wellGeneral, consumeProducts }) => {
  for (let index = 0; index < 8; index += 1) {
    const row = 14 + index;
    const drill = drillStrings[index];
    const casing = casings[index];
    setCellValue(ws, `H${row}`, text(drill?.description));
    setCellValue(ws, `Q${row}`, drill ? round(drill.od, 3) : "");
    setCellValue(ws, `W${row}`, drill ? round(drill.id, 3) : "");
    setCellValue(ws, `AC${row}`, drill ? round(drill.length, 2) : "");
    setCellValue(ws, `AJ${row}`, text(casing?.type || casing?.description));
    setCellValue(ws, `AS${row}`, casing ? round(casing.od, 3) : "");
    setCellValue(ws, `AY${row}`, casing ? round(casing.shoe, 2) : "");
    setCellValue(ws, `BE${row}`, text(casing?.bit));
    setCellValue(ws, `BL${row}`, casing ? round(casing.toc, 2) : "");
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

  for (let index = 0; index < 12; index += 1) {
    const row = 23 + index;
    const pit = activePits[index];
    setCellValue(ws, `BA${row}`, text(pit?.pitName));
    setCellValue(ws, `BN${row}`, pit ? round(getActivePitVolume(pit)) : "");
  }

  const primaryFluid = fluidName || activePits[0]?.fluidType || "";
  const reserveFluid = activePits[1]?.fluidType || primaryFluid;
  const primaryPit = activePits[0]?.pitName || "";
  const reservePit = activePits[1]?.pitName || "";
  [["P","T",primaryFluid],["U","Y",reserveFluid],["AE","AI",reserveFluid],["Z","AD",primaryFluid]].forEach(
    ([start, end, value]) => fillRowRange(ws, 36, start, end, value)
  );
  [["P","T",primaryPit],["U","Y",reservePit],["Z","AD",primaryPit],["AE","AI",reservePit]].forEach(
    ([start, end, value]) => fillRowRange(ws, 37, start, end, value)
  );
  [["P","T",text(wellGeneral?.time)],["U","Y",text(wellGeneral?.time)]].forEach(
    ([start, end, value]) => fillRowRange(ws, 38, start, end, value)
  );
  [["P","T",round(wellGeneral?.suctionT) || ""],["U","Y",round(wellGeneral?.suctionT) || ""]].forEach(
    ([start, end, value]) => fillRowRange(ws, 39, start, end, value)
  );
  [["P","T",round(wellGeneral?.md) || ""],["U","Y",round(wellGeneral?.md) || ""]].forEach(
    ([start, end, value]) => fillRowRange(ws, 40, start, end, value)
  );
  [["P","T",round(activePits[0]?.density) || ""],["U","Y",round(activePits[0]?.density) || ""]].forEach(
    ([start, end, value]) => fillRowRange(ws, 41, start, end, value)
  );

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
}) => {
  const notes = [
    text(report?.notes),
    text(wellGeneral?.activity) ? `Activity: ${wellGeneral.activity}` : "",
    text(wellGeneral?.formation) ? `Formation: ${wellGeneral.formation}` : "",
    wellGeneral?.md ? `Measured Depth: ${round(wellGeneral.md)} ft` : "",
    wellGeneral?.depthDrilled ? `Depth drilled last 24 hrs: ${round(wellGeneral.depthDrilled)} ft` : "",
    well?.wellNameNo ? `Well: ${well.wellNameNo}` : "",
    pad?.fieldBlock ? `Field/Block: ${pad.fieldBlock}` : "",
    summary?.finalActiveVolume ? `Final active volume: ${summary.finalActiveVolume} bbl` : "",
  ].filter(Boolean).join("\n");
  setCellValue(ws, "AJ53", notes || "No additional report notes were saved for this report.");

  pumps.slice(0, 4).forEach((pump, index) => {
    const startColumn = ["L", "R", "X", "AD"][index];
    const baseColumn = columnToNumber(startColumn);
    ws.getRow(100).getCell(baseColumn).value = index + 1;
    ws.getRow(101).getCell(baseColumn).value = round(pump.linerId, 3);
    ws.getRow(102).getCell(baseColumn).value = round(pump.strokeLength, 3);
    ws.getRow(103).getCell(baseColumn).value = round(pump.efficiency, 2);
    ws.getRow(104).getCell(baseColumn).value = round(pump.spm, 2);
    ws.getRow(105).getCell(baseColumn).value = round(pump.displacement, 4);
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
    G: round(item.qty),
    I: round(item.cumulativeUsed),
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
    G: round(item.qty),
    I: round(item.cumulativeUsed),
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
      .sort({ rowNumber: 1, createdAt: 1, _id: 1 })
      .lean();

    if (scoped.length > 0) {
      return scoped;
    }
  }

  return Pump.find({ wellId, ...legacyReportScopeForModel(Pump) })
    .sort({ rowNumber: 1, createdAt: 1, _id: 1 })
    .lean();
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
      addWaterRows, receiveMudRows, returnLostRows, transferRows, otherVolRows, mudLossRows, mudLossStorageRows,
      allOtherVolRows, intervals,
    ] = await Promise.all([
      loadInventorySnapshot({ wellId, reportId }),
      loadReportScopedList(Activity, {
        wellId,
        reportId,
        sort: { createdAt: -1 },
        limit: 10,
      }),
      Well.findById(wellId).lean(),
      loadReportScopedList(DrillString, {
        wellId,
        reportId,
        sort: { createdAt: 1 },
        limit: 8,
      }),
      loadReportScopedList(Casing, {
        wellId,
        reportId,
        sort: { createdAt: 1 },
        limit: 8,
      }),
      loadExportPumps({ wellId, reportId }),
      loadReportScopedList(ConsumeProduct, { wellId, reportId }),
      loadReportScopedList(AddWater, { wellId, reportId }),
      loadReportScopedList(ReceiveMud, { wellId, reportId }),
      loadReportScopedList(ReturnLostMud, { wellId, reportId }),
      loadReportScopedList(TransferMud, { wellId, reportId }),
      loadReportScopedList(OtherVolAddition, { wellId, reportId }),
      loadReportScopedList(MudLoss, { wellId, reportId }),
      loadReportScopedList(MudLossStorage, { wellId, reportId }),
      OtherVolAddition.find({ wellId }).sort({ createdAt: 1, _id: 1 }).lean(),
      Interval.find({ wellId }).sort({ order: 1, createdAt: 1, _id: 1 }).lean(),
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
    const services = inventoryData.filter((item) => item.category === "Service");
    const engineers = inventoryData.filter((item) => item.category === "Engineering");
    const summary = computeVolumeSummary({
      activePits,
      productsUsed: consumeProducts,
      addWaterRows,
      receiveMudRows,
      transferRows,
      returnLostRows,
      otherVolRows,
      mudLossRows,
      mudLossStorageRows,
    });
    const productDailyCost = sumBy(products, (item) => item.costDollar);
    const engineeringDailyCost = sumBy(engineers, (item) => item.costDollar);
    const intervalBitSize = resolveIntervalBitSize(intervals, wellGeneral?.interval);
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
    fillDmrTopSections(dmrSheet, { drillStrings, casings, summary, activePits, fluidName, wellGeneral, consumeProducts });
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
