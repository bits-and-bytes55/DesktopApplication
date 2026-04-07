import ExcelJS from "exceljs";
import { fileURLToPath } from "url";
import InventorySnapshot from "../../modules/FullInventory/InventorySnapshot.js";
import Pit from "../../modules/pit/pit.model.js";
import { Activity } from "../../modules/others/others.model.js";
import Well from "../../modules/well/well.model.js";
import Pad from "../../modules/pad/pad.model.js";
import WellGeneral from "../../modules/wellGeneral/wellGeneralModel.js";

const TEMPLATE_PATH = fileURLToPath(
  new URL("../../../assets/template.xlsx", import.meta.url)
);

const INVENTORY_SHEET_NAME = "Inventory";
const REPORT_NUMBER = "1";

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
  "G67",
  "J67",
  "M67",
  "G68",
  "J68",
  "M68",
  "G69",
  "J69",
  "M69",
  "G70",
  "J70",
  "M70",
  "G71",
  "J71",
  "M71",
  "G72",
  "J72",
  "M72",
  "G73",
  "J73",
  "M73",
  "X67",
  "AA67",
  "AD67",
  "X68",
  "AA68",
  "AD68",
  "X71",
  "AA71",
  "AD71",
  "X72",
  "AA72",
  "AD72",
  "X73",
  "AA73",
  "AD73",
];

const COST_SUMMARY_VALUE_CELLS = [
  "G94",
  "G95",
  "G96",
  "G97",
  "G98",
  "G99",
  "G100",
  "G101",
  "AE94",
  "AE95",
  "AE96",
  "AE97",
  "AE98",
  "AE99",
  "AE100",
  "AE101",
];

const normalizeUnit = (unit = "") =>
  unit.toString().replace(/[()\s]/g, "").toLowerCase();

const convertWithFactors = (value, fromUnit, toUnit, factors) => {
  if (!Number.isFinite(value) || !toUnit || normalizeUnit(fromUnit) === normalizeUnit(toUnit)) {
    return value;
  }

  const fromFactor = factors[normalizeUnit(fromUnit)];
  const toFactor = factors[normalizeUnit(toUnit)];

  if (!fromFactor || !toFactor) {
    return value;
  }

  return (value * fromFactor) / toFactor;
};

const LENGTH_FACTORS = {
  m: 1,
  ft: 0.3048,
  in: 0.0254,
  mm: 0.001,
  cm: 0.01,
  dm: 0.1,
};

const VOLUME_FACTORS = {
  bbl: 0.158987,
  m3: 1,
  l: 0.001,
  gal: 0.00378541,
  ft3: 0.0283168,
  in3: 0.0000163871,
};

const MUD_WEIGHT_FACTORS = {
  ppg: 119.826,
  "kg/m3": 1,
  "g/cm3": 1000,
  "lb/ft3": 16.0185,
  sg: 1000,
};

const setCellValue = (worksheet, address, value = "") => {
  worksheet.getCell(address).value = value ?? "";
};

const clearRows = (worksheet, range, columns) => {
  for (let row = range.start; row <= range.end; row += 1) {
    for (const column of columns) {
      setCellValue(worksheet, `${column}${row}`, "");
    }
  }
};

const writeRows = (worksheet, range, columns, items, mapItem) => {
  clearRows(worksheet, range, columns);

  const maxRows = range.end - range.start + 1;

  items.slice(0, maxRows).forEach((item, index) => {
    const rowNumber = range.start + index;
    const rowData = mapItem(item);

    Object.entries(rowData).forEach(([column, value]) => {
      setCellValue(worksheet, `${column}${rowNumber}`, value);
    });
  });
};

const clearCells = (worksheet, addresses) => {
  addresses.forEach((address) => setCellValue(worksheet, address, ""));
};

const toNumber = (value, fallback = 0) => {
  const parsedValue = Number(value);
  return Number.isFinite(parsedValue) ? parsedValue : fallback;
};

const convertNumericValue = (rawValue, converter, precision = 2) => {
  const numericValue = Number(rawValue);
  if (!Number.isFinite(numericValue)) {
    return rawValue ?? "";
  }

  return Number(converter(numericValue).toFixed(precision));
};

const getReportDate = () => new Date().toLocaleDateString("en-GB");

const getPitVolume = (pit) => pit.volume || pit.capacity || "";

export const exportInventoryReport = async (req, res) => {
  try {
    const { wellId } = req.params;
    const {
      unitSystem = "",
      lengthUnit = "(m)",
      volumeUnit = "(bbl)",
      mudWeightUnit = "(ppg)",
    } = req.query;

    const convertLength = (value) =>
      convertWithFactors(value, "(m)", lengthUnit, LENGTH_FACTORS);
    const convertVolume = (value) =>
      convertWithFactors(value, "(bbl)", volumeUnit, VOLUME_FACTORS);
    const convertMudWeight = (value) =>
      convertWithFactors(value, "(ppg)", mudWeightUnit, MUD_WEIGHT_FACTORS);

const [inventoryData, pits, activities, well, wellGeneral] = await Promise.all([
  InventorySnapshot.find().sort({ category: 1 }),
  Pit.find({ wellId }),
  Activity.find(),
  Well.findById(wellId),
  WellGeneral.findOne({ wellId }).sort({ createdAt: -1 }),
]);
let pad = null;

if (well?.padId) {
  pad = await Pad.findById(well.padId);
}

    const products = inventoryData.filter(
      (item) => item.category === "Product"
    );
    const services = inventoryData.filter(
      (item) => item.category === "Service"
    );
    const engineers = inventoryData.filter(
      (item) => item.category === "Engineering"
    );
    const activePits = pits.filter((pit) => pit.initialActive === true);
    const reservePits = pits.filter((pit) => pit.initialActive === false);

    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.readFile(TEMPLATE_PATH);

    const worksheet = workbook.getWorksheet(INVENTORY_SHEET_NAME);

    if (!worksheet) {
      throw new Error(
        `${INVENTORY_SHEET_NAME} sheet not found in assets/template.xlsx`
      );
    }

    const inventorySheetIndex = workbook.worksheets.findIndex(
      (sheet) => sheet.name === INVENTORY_SHEET_NAME
    );

    if (inventorySheetIndex >= 0) {
      const currentView = workbook.views?.[0] ?? { visibility: "visible" };

      workbook.views = [
        {
          ...currentView,
          firstSheet: inventorySheetIndex,
          activeTab: inventorySheetIndex,
        },
      ];
    }

    setCellValue(worksheet, "I2", "Daily Inventory Report");
    setCellValue(worksheet, "V2", REPORT_NUMBER);
    setCellValue(worksheet, "AE2", unitSystem ? `Units: ${unitSystem}` : "");

    setCellValue(worksheet, "L7", well?._id?.toString() || "");
    setCellValue(worksheet, "U7", wellGeneral?.date || getReportDate());
    setCellValue(worksheet, "AC7", wellGeneral?.reportNo || REPORT_NUMBER);

    setCellValue(worksheet, "D8", well?.wellNameNo || "-");
setCellValue(worksheet, "L8", pad?.rig || "-");
setCellValue(worksheet, "U8", pad?.fieldBlock || "-");
setCellValue(worksheet, "AC8", pad?.stateProvince || "-");

setCellValue(worksheet, "D9", pad?.operator || "-");
setCellValue(worksheet, "L9", pad?.contractor || "-");
setCellValue(worksheet, "U9", wellGeneral?.formation || "-");
setCellValue(
  worksheet,
  "AC9",
  convertNumericValue(wellGeneral?.md, convertLength, 2)
);

setCellValue(worksheet, "D10", wellGeneral?.operatorRep || pad?.operatorRep || "-");
setCellValue(worksheet, "L10", wellGeneral?.contractorRep || pad?.contractorRep || "-");
setCellValue(
  worksheet,
  "U10",
  wellGeneral?.inc || wellGeneral?.azi
    ? `${wellGeneral?.inc || 0} / ${wellGeneral?.azi || 0}`
    : "-"
);
setCellValue(
  worksheet,
  "AC10",
  convertNumericValue(wellGeneral?.tvd, convertLength, 2)
);

setCellValue(worksheet, "D11", well?.spudDate || "-");
setCellValue(worksheet, "L11", "-");
setCellValue(worksheet, "U11", wellGeneral?.activity || "-");
setCellValue(
  worksheet,
  "AC11",
  convertNumericValue(wellGeneral?.depthDrilled, convertLength, 2)
);

    writeRows(
      worksheet,
      PRODUCT_ROWS,
      PRODUCT_COLUMNS,
      products,
      (item) => ({
        A: item.itemName || "",
        F: item.unit || "",
        I: toNumber(item.price),
        K: toNumber(item.initial),
        M: toNumber(item.rec),
        O: toNumber(item.cumulativeRec),
        Q: toNumber(item.ret),
        S: toNumber(item.cumulativeRet),
        U: toNumber(item.used),
        W: toNumber(item.cumulativeUsed),
        Y: toNumber(item.final),
        AA: toNumber(item.costDollar),
        AC: "",
        AE: "",
      })
    );

    clearCells(worksheet, SUMMARY_VALUE_CELLS);

    writeRows(
      worksheet,
      SERVICE_ROWS,
      SERVICE_COLUMNS,
      services,
      (item) => ({
        A: item.itemName || "",
        G: toNumber(item.qty),
        I: toNumber(item.cumulativeUsed),
        K: toNumber(item.costDollar),
      })
    );

    writeRows(
      worksheet,
      ACTIVE_PIT_ROWS,
      PIT_COLUMNS,
      activePits,
      (pit) => ({
        M: pit.pitName || "",
        S: convertNumericValue(getPitVolume(pit), convertVolume, 2),
        U: convertNumericValue(pit.density, convertMudWeight, 2),
        W: pit.fluidType || "",
      })
    );

    writeRows(
      worksheet,
      TIME_ROWS,
      TIME_COLUMNS,
      activities,
      (activity) => ({
        AA: activity.description || "",
        AE: toNumber(activity.hours),
      })
    );

    writeRows(
      worksheet,
      ENGINEERING_ROWS,
      SERVICE_COLUMNS,
      engineers,
      (item) => ({
        A: item.itemName || "",
        G: toNumber(item.qty),
        I: toNumber(item.cumulativeUsed),
        K: toNumber(item.costDollar),
      })
    );

    writeRows(
      worksheet,
      RESERVE_ROWS,
      PIT_COLUMNS,
      reservePits,
      (pit) => ({
        M: pit.pitName || "",
        S: convertNumericValue(pit.capacity, convertVolume, 2),
        U: "",
        W: "",
      })
    );

    clearCells(worksheet, COST_SUMMARY_VALUE_CELLS);

    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    );
    res.setHeader(
      "Content-Disposition",
      "attachment; filename=Daily_Inventory_Report.xlsx"
    );

    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
