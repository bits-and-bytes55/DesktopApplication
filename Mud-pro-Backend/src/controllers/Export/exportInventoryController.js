import ExcelJS from "exceljs";
import path from "path";

import Company from "../../modules/company/company.model.js";
import InventorySnapshot from "../../modules/FullInventory/InventorySnapshot.js";
import Pit from "../../modules/pit/pit.model.js";
import { Activity } from "../../modules/others/others.model.js";

export const exportInventoryReport = async (req, res) => {
  try {

    // =========================
    // DATA FETCH
    // =========================
    const inventoryData = await InventorySnapshot.find().sort({ category: 1 });

    const products = inventoryData.filter(i => i.category === "Product");
    const services = inventoryData.filter(i => i.category === "Service");
    const engineers = inventoryData.filter(i => i.category === "Engineering");

    const pits = await Pit.find();
    const activities = await Activity.find();

    const activePits = pits.filter(p => p.initialActive === true);
    const reservePits = pits.filter(p => p.initialActive === false);

    // =========================
    // LOAD TEMPLATE (IMPORTANT)
    // =========================
    const workbook = new ExcelJS.Workbook();

    await workbook.xlsx.readFile(
      path.join("assets", "template.xlsx")   // 👉 अपनी file का नाम
    );

    const worksheet = workbook.getWorksheet(1);

    // =========================
    // PRODUCTS (Row 14)
    // =========================
    let productRow = 14;

    products.forEach((item, i) => {
      const row = worksheet.getRow(productRow + i);

      row.getCell(1).value = item.itemName || "";
      row.getCell(2).value = item.unit || "";
      row.getCell(3).value = item.price || 0;
      row.getCell(4).value = item.initial || 0;
      row.getCell(5).value = item.rec || 0;
      row.getCell(6).value = item.cumulativeRec || 0;
      row.getCell(7).value = item.ret || 0;
      row.getCell(8).value = item.cumulativeRet || 0;
      row.getCell(9).value = item.used || 0;
      row.getCell(10).value = item.cumulativeUsed || 0;
      row.getCell(11).value = item.final || 0;
      row.getCell(12).value = item.costDollar || 0;
    });

    // =========================
    // SERVICES (Row 76)
    // =========================
    let serviceRow = 76;

    services.forEach((s, i) => {
      const row = worksheet.getRow(serviceRow + i);

      row.getCell(1).value = s.itemName || "";
      row.getCell(2).value = s.qty || 0;
      row.getCell(3).value = s.cumulativeUsed || 0;
      row.getCell(4).value = s.costDollar || 0;
    });

    // =========================
    // PIT (Active) (Row 77)
    // =========================
    let pitRow = 77;

    activePits.forEach((pit, i) => {
      const row = worksheet.getRow(pitRow + i);

      row.getCell(5).value = pit.pitName || "";
      row.getCell(6).value = pit.capacity || 0;
      row.getCell(7).value = pit.density || "";
      row.getCell(8).value = pit.fluidType || "";
    });

    // =========================
    // TIME BREAKDOWN (Row 76)
    // =========================
    let timeRow = 76;

    activities.forEach((act, i) => {
      const row = worksheet.getRow(timeRow + i);

      row.getCell(10).value = act.description || "";
      row.getCell(11).value = act.hours || 0;
    });

    // =========================
    // ENGINEERING (Row 87)
    // =========================
    let engRow = 87;

    engineers.forEach((e, i) => {
      const row = worksheet.getRow(engRow + i);

      row.getCell(1).value = e.itemName || "";
      row.getCell(2).value = e.qty || 0;
      row.getCell(3).value = e.cumulativeUsed || 0;
      row.getCell(4).value = e.costDollar || 0;
    });

    // =========================
    // RESERVE PITS (Row 95)
    // =========================
    let reserveRow = 95;

    reservePits.forEach((pit, i) => {
      const row = worksheet.getRow(reserveRow + i);

      row.getCell(5).value = pit.pitName || "";
      row.getCell(6).value = pit.capacity || 0;
      row.getCell(7).value = pit.density || "";
      row.getCell(8).value = pit.fluidType || "";
    });

    // =========================
    // RESPONSE
    // =========================
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
      message: error.message
    });
  }
};