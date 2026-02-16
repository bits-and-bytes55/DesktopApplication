import ExcelJS from "exceljs";
import path from "path";
import Company from "../../modules/company/company.model.js";
import InventorySnapshot from "../../modules/FullInventory/InventorySnapshot.js";

export const exportInventoryReport = async (req, res) => {
  try {

    const company = await Company.findOne().sort({ createdAt: -1 });
    const inventoryData = await InventorySnapshot.find().sort({ category: 1 });

    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet("Daily Inventory Report");

    worksheet.columns = [
      { width: 18 },
      { width: 18 },
      { width: 12 },
      { width: 12 },
      { width: 12 },
      { width: 12 },
      { width: 12 },
      { width: 12 },
      { width: 12 },
      { width: 12 },
      { width: 12 },
      { width: 12 },
      { width: 12 },
      { width: 15 }
    ];

    // ===========================
    // LOGOS
    // ===========================

    const leftlogo = workbook.addImage({
      filename: path.join("assets", "leftlogo.jpeg"),
      extension: "jpeg",
    });

    const rightlogo = workbook.addImage({
      filename: path.join("assets", "rightlogo.jpeg"),
      extension: "jpeg",
    });

    worksheet.addImage(leftlogo, "A1:B4");
    worksheet.addImage(rightlogo, "M1:N4");

    // ===========================
    // TITLE
    // ===========================

    worksheet.mergeCells("C1:L3");
    worksheet.getCell("C1").value = "Daily Inventory Report";
    worksheet.getCell("C1").font = { size: 20, bold: true };
    worksheet.getCell("C1").alignment = { horizontal: "center", vertical: "middle" };

    // ===========================
    // COMPANY INFO (ONLY FROM DB)
    // ===========================

    worksheet.addRow([]);
    worksheet.addRow(["Company Name:", company?.companyName || ""]);
    worksheet.addRow(["Address:", company?.address || ""]);
    worksheet.addRow(["Phone:", company?.phone || ""]);
    worksheet.addRow(["Email:", company?.email || ""]);
    worksheet.addRow([]);

    // ===========================
    // PRODUCTS INVENTORY BAR
    // ===========================

    const productHeaderRow = worksheet.addRow(["Products Inventory"]);
    worksheet.mergeCells(`A${productHeaderRow.number}:N${productHeaderRow.number}`);
    productHeaderRow.font = { bold: true, color: { argb: "FFFFFF" } };
    productHeaderRow.alignment = { horizontal: "center" };
    productHeaderRow.eachCell(cell => {
      cell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "006400" }
      };
    });

    // ===========================
    // TABLE HEADER
    // ===========================

    const tableHeader = worksheet.addRow([
      "Product Name",
      "Price",
      "Start Qty",
      "Received",
      "Cumulative Rec",
      "Returned",
      "Cumulative Ret",
      "Adj",
      "Used",
      "Cumulative Used",
      "Final",
      "Subtotal",
      "Report Date"
    ]);

    tableHeader.font = { bold: true };

    tableHeader.eachCell(cell => {
      cell.border = {
        top: { style: "thin" },
        left: { style: "thin" },
        bottom: { style: "thin" },
        right: { style: "thin" }
      };
    });

    // ===========================
    // DATA ROWS
    // ===========================

    inventoryData.forEach(item => {
      const row = worksheet.addRow([
        item.itemName,
        item.price,
        item.initial,
        item.rec,
        item.cumulativeRec,
        item.ret,
         item.cumulativeRet,
        item.adj,
        item.used,
        item.cumulativeUsed,
        item.final,
        item.subtotal,
        new Date(item.reportDate).toLocaleDateString()
      ]);

      row.eachCell(cell => {
        cell.border = {
          top: { style: "thin" },
          left: { style: "thin" },
          bottom: { style: "thin" },
          right: { style: "thin" }
        };
      });
    });

    // ===========================
    // RESPONSE
    // ===========================

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
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
