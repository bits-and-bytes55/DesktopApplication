import ExcelJS from "exceljs";
import path from "path";
import Company from "../../modules/company/company.model.js";
import InventorySnapshot from "../../modules/FullInventory/InventorySnapshot.js";

export const exportInventoryReport = async (req, res) => {
  try {
    const company = await Company.findOne().sort({ createdAt: -1 });
    const inventoryData = await InventorySnapshot.find().sort({ category: 1 });

    console.log("Export Count:", inventoryData.length);

    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet("Daily Inventory Report");

    // OPTIMIZED COLUMN WIDTHS FOR FULL SCREEN VIEW
worksheet.columns = [
  { width: 30 },
  { width: 15 },
  { width: 15 },
  { width: 12 },
  { width: 12 },
  { width: 15 },
  { width: 12 },
  { width: 15 },
  { width: 12 },
  { width: 15 },
  { width: 12 },
  { width: 15 },
  { width: 12 },
  { width: 12 }
];

    // ===========================
    // CLEAR ANY EXISTING ROWS (FIX FOR DUPLICATE DATA)
    // ===========================
    // worksheet.spliceRows(1, worksheet.rowCount);

    // ===========================
    // LOGOS
    // ===========================
    try {
      const leftLogo = workbook.addImage({
        filename: path.join("assets", "leftlogo.jpeg"),
        extension: "jpeg",
      });
      const rightLogo = workbook.addImage({
        filename: path.join("assets", "rightlogo.jpeg"),
        extension: "jpeg",
      });
      
      worksheet.addImage(leftLogo, "A1:C3");
      worksheet.addImage(rightLogo, "L1:N3");
    } catch (err) {
      console.log("Logo not found, continuing...");
    }

    // ===========================
    // TITLE - SINGLE INSTANCE
    // ===========================
    worksheet.mergeCells("D1:K2");
    const titleCell = worksheet.getCell("D1");
    titleCell.value = "Daily Inventory Report";
    titleCell.font = { size: 24, bold: true, color: { argb: "003366" } };
    titleCell.alignment = { horizontal: "center", vertical: "middle" };

    // ===========================
    // COMPANY INFO (ONCE ONLY)
    // ===========================
    let currentRow = 5; // Start after title and logos
    
    if (company) {
      worksheet.getCell(`A${currentRow}`).value = "Company Name:";
      worksheet.getCell(`A${currentRow}`).font = { bold: true };
      worksheet.getCell(`B${currentRow}`).value = company.companyName || "";
      
      worksheet.getCell(`A${currentRow + 1}`).value = "Address:";
      worksheet.getCell(`A${currentRow + 1}`).font = { bold: true };
      worksheet.getCell(`B${currentRow + 1}`).value = company.address || "";
      
      worksheet.getCell(`A${currentRow + 2}`).value = "Phone:";
      worksheet.getCell(`A${currentRow + 2}`).font = { bold: true };
      worksheet.getCell(`B${currentRow + 2}`).value = company.phone || "";
      
      worksheet.getCell(`A${currentRow + 3}`).value = "Email:";
      worksheet.getCell(`A${currentRow + 3}`).font = { bold: true };
      worksheet.getCell(`B${currentRow + 3}`).value = company.email || "";
      
      currentRow += 5; // Move pointer after company info + empty row
    } else {
      currentRow += 1;
      
    }

    // ===========================
    // PRODUCTS INVENTORY HEADER
    // ===========================
    worksheet.mergeCells(`A${currentRow}:N${currentRow}`);
    const productHeaderCell = worksheet.getCell(`A${currentRow}`);
    productHeaderCell.value = "Products Inventory";
    productHeaderCell.font = { bold: true, size: 16, color: { argb: "FFFFFF" } };
    productHeaderCell.alignment = { horizontal: "center", vertical: "middle" };
    productHeaderCell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "003366" }
    };
    
    currentRow++;

    // ===========================
    // TABLE HEADER
    // ===========================
    const tableHeaderRow = worksheet.getRow(currentRow);
    tableHeaderRow.values = [
      "Product Name",
      "Size",
      "Price (Kwd)",
      "Start Qty",
      "Received",
      "Cum. Rec.",
      "Returned",
      "Cum. Ret.",
      "Used",
      "Cum. Used",
      "Final",
      "Cost (Kwd)",
      "Starting",
      "Ending"
    ];

    tableHeaderRow.font = { bold: true, color: { argb: "FFFFFF" } };
    tableHeaderRow.height = 30;
    
    tableHeaderRow.eachCell(cell => {
      cell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "4682B4" }
      };
      cell.border = {
        top: { style: "thin" },
        left: { style: "thin" },
        bottom: { style: "thin" },
        right: { style: "thin" }
      };
      cell.alignment = { horizontal: "center", vertical: "middle" };
      cell.font = { bold: true, size: 12 };
    });
    
    currentRow++;

    // ===========================
    // DATA ROWS - SINGLE INSTANCE
    // ===========================
    let totalCost = 0;
    let rowIndex = 0;
    
    // CLEAR ANY EXISTING DATA ROWS BEFORE ADDING NEW ONES
    const startDataRow = currentRow;
    
    inventoryData.forEach((item) => {
      const cost = (item.price || 0) * (item.used || 0);
      totalCost += cost;
      
      const row = worksheet.getRow(currentRow + rowIndex);
      row.values = [
        item.itemName || "",
        item.size || "1.00 Ton",
        item.price || 0,
        item.initial || 0,
        item.rec || 0,
        item.cumulativeRec || 0,
        item.ret || 0,
        item.cumulativeRet || 0,
        item.used || 0,
        item.cumulativeUsed || 0,
        item.final || 0,
        cost.toFixed(3),
        item.starting || "",
        item.ending || ""
      ];

      // Apply styling to each cell
      row.eachCell((cell, colNumber) => {
        cell.border = {
          top: { style: "thin" },
          left: { style: "thin" },
          bottom: { style: "thin" },
          right: { style: "thin" }
        };
        cell.alignment = { horizontal: "center", vertical: "middle" };
        
        // Alternate row colors
        if (rowIndex % 2 === 0) {
          cell.fill = {
            type: "pattern",
            pattern: "solid",
            fgColor: { argb: "F9F9F9" }
          };
        }

        // Format price columns
        if (colNumber === 3 || colNumber === 12) {
          cell.numFmt = '#,##0.000';
        }
      });
      
      rowIndex++;
    });

    // Update current row to after data
    currentRow += rowIndex;

    // ===========================
    // TOTAL ROW
    // ===========================
    if (inventoryData.length > 0) {
      currentRow++; // Empty row
      const totalRow = worksheet.getRow(currentRow);
      totalRow.values = Array(14).fill("");
      totalRow.getCell(11).value = "Total Cost:";
      totalRow.getCell(12).value = totalCost.toFixed(3);
      
      totalRow.getCell(11).font = { bold: true, size: 12 };
      totalRow.getCell(12).font = { bold: true, size: 12 };
      totalRow.getCell(12).fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FFE4B5" }
      };
    }

    // ===========================
    // FULL SCREEN OPTIMIZATIONS
    // ===========================
    
    // Set print area to fit all columns on one page
    worksheet.pageSetup = {
      fitToPage: true,
      fitToWidth: 1,
      fitToHeight: false,
      orientation: 'landscape',
      margins: {
        left: 0.25,
        right: 0.25,
        top: 0.5,
        bottom: 0.5,
        header: 0.3,
        footer: 0.3
      }
    };

    // Auto-filter for easy data navigation
    worksheet.autoFilter = {
      from: { row: startDataRow - 1, column: 1 },
      to: { row: startDataRow - 1, column: 14 }
    };

    // Freeze panes for better scrolling
    worksheet.views = [
      { 
        state: "frozen", 
        xSplit: 0, 
        ySplit: startDataRow - 1,  // Freeze at table header
        activeCell: "A1" 
      }
    ];

    // Set row heights for better visibility
    for (let i = startDataRow; i < currentRow; i++) {
      worksheet.getRow(i).height = 22;
    }

    // ===========================
    // RESPONSE
    // ===========================
    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    );

    const fileName = `Daily_Inventory_Report_${new Date().toISOString().split('T')[0]}.xlsx`;
    res.setHeader(
      "Content-Disposition",
      `attachment; filename=${fileName}`
    );

    await workbook.xlsx.write(res);
    res.end();

  } catch (error) {
    console.log("Export Error:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};