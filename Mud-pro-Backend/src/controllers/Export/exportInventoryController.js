import ExcelJS from "exceljs";
import path from "path";
import Company from "../../modules/company/company.model.js";
import InventorySnapshot from "../../modules/FullInventory/InventorySnapshot.js";
import Pit from "../../modules/pit/pit.model.js";

export const exportInventoryReport = async (req, res) => {
  try {
    const company = await Company.findOne().sort({ createdAt: -1 });
    const inventoryData = await InventorySnapshot.find().sort({ category: 1 });
    const products = inventoryData.filter(i => i.category === "Product");
const services = inventoryData.filter(i => i.category === "Service");
const engineers = inventoryData.filter(i => i.category === "Engineering");
const pits = await Pit.find();

const activePits = pits.filter(p => p.initialActive === true);
const reservePits = pits.filter(p => p.initialActive === false);

    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet("Daily Inventory Report");

    worksheet.pageSetup = {
  paperSize: 9,
  orientation: "landscape",
  fitToPage: true,
  fitToWidth: 1,
  fitToHeight: false
};


    // ===========================
    // 1. PERFECT COLUMN WIDTHS
    // ===========================
    worksheet.columns = [
      { key: 'name', width: 20 },   // A: Product Name
      { key: 'size', width: 12 },   // B: Size
      { key: 'price', width: 12 },  // C: Price
      { key: 'start', width: 14 },  // D: Start Qty
      { key: 'rec', width: 14 },    // E: Received
      { key: 'cumrec', width: 12 }, // F: Cum Rec
      { key: 'ret', width: 12 },    // G: Returned
      { key: 'cumret', width: 14 }, // H: Cum Ret
      { key: 'used', width: 12 },   // I: Used
      { key: 'cumused', width: 14 },// J: Cum Used
      { key: 'final', width: 12 },  // K: Final
      { key: 'cost', width: 14 },   // L: Cost
      { key: 'cstart', width: 12 }, // M: Conc Start
      { key: 'cend', width: 12 }    // N: Conc End
    ];

    // ===========================
    // 2. LOGOS
    // ===========================
    try {
      const leftlogo = workbook.addImage({
        filename: path.join("assets", "leftlogo.jpeg"),
        extension: "jpeg",
      });
      const rightlogo = workbook.addImage({
        filename: path.join("assets", "rightlogo.jpeg"),
        extension: "jpeg",
      });
      
      // Logos added properly
      worksheet.addImage(leftlogo, "A1:B4");
      worksheet.addImage(rightlogo, "N1:N4"); // Fixed right logo to N col
    } catch (e) {
      console.log("Logos not found, skipping image insertion.");
    }

    // ===========================
    // 3. TITLE & REPORT NO. (WITH BORDERS)
    // ===========================
    
    // Main Title Box
    worksheet.mergeCells("D1:K4");
    const titleCell = worksheet.getCell("D1");
    titleCell.value = "Daily Inventory Report";
    titleCell.font = { name: 'Arial', size: 20, bold: true };
    titleCell.alignment = { horizontal: "center", vertical: "middle" };
    
    // Main Title Box Borders
    for(let r=1; r<=4; r++) {
        for(let c=4; c<=11; c++) {
            worksheet.getCell(r, c).border = { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: "thin" }, right: { style: "thin" } };
        }
    }

    // Report No Box (Green)
    worksheet.mergeCells("L1:M4");
    const reportNoLabel = worksheet.getCell("L1");
    reportNoLabel.value = "1";
    reportNoLabel.font = { size: 18, bold: true };
    reportNoLabel.alignment = { horizontal: "center", vertical: "middle" };
    reportNoLabel.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFEBF1DE' } }; // Light Green
    
    // Report No Box Borders
    for(let r=1; r<=4; r++) {
        for(let c=12; c<=13; c++) {
            worksheet.getCell(r, c).border = { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: "thin" }, right: { style: "thin" } };
        }
    }


    // ===========================
    // 4. BALANCED STATIC TOP GRID
    // ===========================
    
    const labelStyle = {
      font: { bold: true, size: 10 },
      fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFEBF1DE' } }, // Light Green
      alignment: { vertical: 'middle', horizontal: 'left', indent: 1 },
      border: { top: { style: 'thin' }, left: { style: 'thin' }, bottom: { style: 'thin' }, right: { style: 'thin' } }
    };
    
    const valStyle = {
      font: { size: 10 },
      alignment: { vertical: 'middle', horizontal: 'center' },
      border: { top: { style: 'thin' }, left: { style: 'thin' }, bottom: { style: 'thin' }, right: { style: 'thin' } }
    };

    // FIX: Optimized Grid Drawer to make all boxes look equal width
    const drawGridRow = (rowNum, c1, v1, c2, v2, c3, v3, c4, v4) => {
        const r = worksheet.getRow(rowNum);
        r.height = 20;

        // Label 1 (Col A)
        const cell1 = worksheet.getCell(`A${rowNum}`); cell1.value = c1; cell1.style = labelStyle;
        
        // Value 1 (Col B & C)
        worksheet.mergeCells(`B${rowNum}:C${rowNum}`);
        const val1 = worksheet.getCell(`B${rowNum}`); val1.value = v1; val1.style = valStyle;

        // Label 2 (Col D & E)
        worksheet.mergeCells(`D${rowNum}:E${rowNum}`);
        const cell2 = worksheet.getCell(`D${rowNum}`); cell2.value = c2; cell2.style = labelStyle;

        // Value 2 (Col F & G)
        worksheet.mergeCells(`F${rowNum}:G${rowNum}`);
        const val2 = worksheet.getCell(`F${rowNum}`); val2.value = v2; val2.style = valStyle;

        // Label 3 (Col H & I)
        worksheet.mergeCells(`H${rowNum}:I${rowNum}`);
        const cell3 = worksheet.getCell(`H${rowNum}`); cell3.value = c3; cell3.style = labelStyle;

        // Value 3 (Col J & K)
        worksheet.mergeCells(`J${rowNum}:K${rowNum}`);
        const val3 = worksheet.getCell(`J${rowNum}`); val3.value = v3; val3.style = valStyle;

        // Label 4 (Col L)
        const cell4 = worksheet.getCell(`L${rowNum}`); cell4.value = c4; cell4.style = labelStyle;

        // Value 4 (Col M & N)
        worksheet.mergeCells(`M${rowNum}:N${rowNum}`);
        const val4 = worksheet.getCell(`M${rowNum}`); val4.value = v4; val4.style = valStyle;

        // Ensure all merged cells get borders properly
        for(let col=1; col<=14; col++) {
            r.getCell(col).border = { top: { style: 'thin' }, left: { style: 'thin' }, bottom: { style: 'thin' }, right: { style: 'thin' } };
        }
    };

    // --- Row 5: Project ID Row ---
    const r5 = worksheet.getRow(5); r5.height = 20;
    
    worksheet.mergeCells('D5:E5'); const l1 = worksheet.getCell('D5'); l1.value = 'Project ID'; l1.style = labelStyle;
    worksheet.mergeCells('F5:G5'); const v1 = worksheet.getCell('F5'); v1.style = valStyle; // Blank
    worksheet.mergeCells('H5:I5'); const l2 = worksheet.getCell('H5'); l2.value = 'Report Date'; l2.style = labelStyle;
    worksheet.mergeCells('J5:K5'); const v2 = worksheet.getCell('J5'); v2.value = new Date().toLocaleDateString('en-GB'); v2.style = valStyle;
    const l3 = worksheet.getCell('L5'); l3.value = 'Report No.'; l3.style = labelStyle;
    worksheet.mergeCells('M5:N5'); const v3 = worksheet.getCell('M5'); v3.value = '1'; v3.style = valStyle;
    
    for(let col=4; col<=14; col++) {
        r5.getCell(col).border = { top: { style: 'thin' }, left: { style: 'thin' }, bottom: { style: 'thin' }, right: { style: 'thin' } };
    }

    // --- Row 6-9: Exact Text Match ---
    drawGridRow(6, 'Well Name', '-', 'Rig Name', '-', 'Field/Block', '-', 'Location/State', '-');
    drawGridRow(7, 'Operator', '-', 'Contractor', '-', 'Formation', '-', 'MD (ft)', '-');
    drawGridRow(8, 'Operator Rep', '-', 'Contractor Rep', '-', 'Inclination/Azimuth', '-', 'TVD (ft)', '-');
    drawGridRow(9, 'Spud Date', '-', 'Fluid Name', '-', 'Activity', '-', 'Bit Depth (ft)', '-');


    // ===========================
    // 5. GREEN HEADERS
    // ===========================
    
    // Row 10: "Products Inventory" and "Concentration"
    const titleRowIdx = 10;
    worksheet.mergeCells(`A${titleRowIdx}:L${titleRowIdx}`);
    const prodTitle = worksheet.getCell(`A${titleRowIdx}`);
    prodTitle.value = "Products Inventory";
    prodTitle.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF006100" } }; // Dark Green
    prodTitle.font = { bold: true, color: { argb: "FFFFFFFF" }, size: 11 };
    prodTitle.alignment = { horizontal: "center", vertical: "middle" };

    worksheet.mergeCells(`M${titleRowIdx}:N${titleRowIdx}`);
    const concTitle = worksheet.getCell(`M${titleRowIdx}`);
    concTitle.value = "Concentration (lb/bbl)";
    concTitle.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF006100" } }; // Dark Green
    concTitle.font = { bold: true, color: { argb: "FFFFFFFF" }, size: 11 };
    concTitle.alignment = { horizontal: "center", vertical: "middle" };

    for(let col=1; col<=14; col++) {
        worksheet.getCell(titleRowIdx, col).border = { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: "thin" }, right: { style: "thin" } };
    }

    // Row 11: Sub-headers
    const tableHeader = worksheet.getRow(11);
    tableHeader.values = [
      "Product Name", "Size", "Price", "Start Qty", "Received", "Cum. Rec.", 
      "Returned", "Cum. Ret.", "Used", "Cum. Used", "Final", "Cost ($)", 
      "Starting", "Ending"
    ];
    tableHeader.height = 25;

    tableHeader.eachCell((cell) => {
      cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FFEBF1DE" } }; // Light Green
      cell.font = { bold: true, size: 10 };
      cell.alignment = { horizontal: "center", vertical: "middle", wrapText: true };
      cell.border = { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: "thin" }, right: { style: "thin" } };
    });


    // ===========================
    // 6. DYNAMIC DATA INJECTION
    // ===========================

    products.forEach(item => {
      const row = worksheet.addRow([
        item.itemName,              // Product Name
        item.unit,                         // Size
        item.price ? Number(item.price) : 0, // Price converted to Number
        item.initial,               // Start Qty
        item.rec,                   // Received
        item.cumulativeRec,         // Cum Rec
        item.ret,                   // Returned
        item.cumulativeRet,         // Cum Ret
        item.used,                  // Used
        item.cumulativeUsed,        // Cum Used
        item.final,                 // Final
        item.costDollar ? Number(item.costDollar) : 0, // Cost converted to Number
        "",                         // Starting Conc
        ""                          // Ending Conc
      ]);

      row.eachCell((cell, colNum) => {
        // Border har ek cell pe
        cell.border = { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: "thin" }, right: { style: "thin" } };
        
        // Alignment
        if (colNum === 1) {
            cell.alignment = { vertical: 'middle', horizontal: 'left', indent: 1 };
        } else {
            cell.alignment = { vertical: 'middle', horizontal: 'center' };
        }

        // FIX: Remove ugly decimals (e.g. 192.85714 becomes 192.86)
        if (typeof cell.value === 'number') {
            if (cell.value % 1 !== 0) { // check if it has decimals
                cell.numFmt = '#,##0.00';
            }
        }
      });
    });
// ===========================
// 7. VOLUME ACCOUNTING SUMMARY UI
// ===========================

const startRow = worksheet.lastRow.number + 2;

// Main Title
worksheet.mergeCells(`A${startRow}:N${startRow}`);
const volTitle = worksheet.getCell(`A${startRow}`);
volTitle.value = "Volume Accounting Summary";
volTitle.font = { bold: true, size: 12, color: { argb: "FFFFFFFF" } };
volTitle.alignment = { horizontal: "center", vertical: "middle" };
volTitle.fill = {
  type: "pattern",
  pattern: "solid",
  fgColor: { argb: "FF006100" }
};

// Section Headers
const headerRow = startRow + 1;

worksheet.mergeCells(`A${headerRow}:E${headerRow}`);
worksheet.getCell(`A${headerRow}`).value = "Volume Additions (bbl)";
worksheet.getCell(`A${headerRow}`).font = { bold: true };
worksheet.getCell(`A${headerRow}`).alignment = { horizontal: "center" };

worksheet.mergeCells(`F${headerRow}:J${headerRow}`);
worksheet.getCell(`F${headerRow}`).value = "Volume Transfers (bbl)";
worksheet.getCell(`F${headerRow}`).font = { bold: true };
worksheet.getCell(`F${headerRow}`).alignment = { horizontal: "center" };

worksheet.mergeCells(`K${headerRow}:N${headerRow}`);
worksheet.getCell(`K${headerRow}`).value = "Volume Losses (bbl)";
worksheet.getCell(`K${headerRow}`).font = { bold: true };
worksheet.getCell(`K${headerRow}`).alignment = { horizontal: "center" };


// Sub Headers
const subHeaderRow = headerRow + 1;

worksheet.getRow(subHeaderRow).values = [
  "Type", "Daily", "Interval", "Well",
  "",
  "Type", "Daily", "Interval", "Well",
  "",
  "Type", "Daily", "Interval", "Well"
];

worksheet.getRow(subHeaderRow).eachCell(cell => {
  cell.font = { bold: true };
  cell.alignment = { horizontal: "center" };
  cell.border = {
    top: { style: "thin" },
    left: { style: "thin" },
    bottom: { style: "thin" },
    right: { style: "thin" }
  };
});


// UI Rows (Dynamic Data Later)
const rows = [
  ["Whole Mud", "", "", ""],
  ["Oil", "", "", ""],
  ["Water", "", "", ""],
  ["Products", "", "", ""],
  ["Weight Material", "", "", ""],
  ["Transferred from Reserve System", "", "", ""]
];

let currentRow = subHeaderRow + 1;

rows.forEach(r => {

  worksheet.getCell(`A${currentRow}`).value = r[0];
  worksheet.getCell(`B${currentRow}`).value = "";
  worksheet.getCell(`C${currentRow}`).value = "";
  worksheet.getCell(`D${currentRow}`).value = "";

  worksheet.getCell(`F${currentRow}`).value = "";
  worksheet.getCell(`G${currentRow}`).value = "";
  worksheet.getCell(`H${currentRow}`).value = "";
  worksheet.getCell(`I${currentRow}`).value = "";

  worksheet.getCell(`K${currentRow}`).value = "";
  worksheet.getCell(`L${currentRow}`).value = "";
  worksheet.getCell(`M${currentRow}`).value = "";
  worksheet.getCell(`N${currentRow}`).value = "";

  for (let c = 1; c <= 14; c++) {
    worksheet.getCell(currentRow, c).border = {
      top: { style: "thin" },
      left: { style: "thin" },
      bottom: { style: "thin" },
      right: { style: "thin" }
    };

    worksheet.getCell(currentRow, c).alignment = {
      horizontal: "center",
      vertical: "middle"
    };
  }

  currentRow++;

});


// Total Rows

worksheet.getCell(`A${currentRow}`).value = "Total Volume Additions";
worksheet.mergeCells(`A${currentRow}:D${currentRow}`);

worksheet.getCell(`F${currentRow}`).value = "Transfers Total";
worksheet.mergeCells(`F${currentRow}:I${currentRow}`);

worksheet.getCell(`K${currentRow}`).value = "Total Volume Losses";
worksheet.mergeCells(`K${currentRow}:N${currentRow}`);

worksheet.getRow(currentRow).eachCell(cell => {
  cell.font = { bold: true };
  cell.border = {
    top: { style: "thin" },
    left: { style: "thin" },
    bottom: { style: "thin" },
    right: { style: "thin" }
  };
});

// =====================================================
// SERVICES | PIT INFORMATION | TIME BREAKDOWN
// =====================================================

let sectionRow = worksheet.lastRow.number + 2;

// ---------------- SERVICES ----------------

worksheet.mergeCells(`A${sectionRow}:D${sectionRow}`);
const srvTitle = worksheet.getCell(`A${sectionRow}`);
srvTitle.value = "Services";
srvTitle.font = { bold: true, color: { argb: "FFFFFFFF" } };
srvTitle.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF006100" } };
srvTitle.alignment = { horizontal: "center" };

// ---------------- PIT INFO ----------------

worksheet.mergeCells(`E${sectionRow}:H${sectionRow}`);
const pitTitle = worksheet.getCell(`E${sectionRow}`);
pitTitle.value = "Pit Information";
pitTitle.font = { bold: true, color: { argb: "FFFFFFFF" } };
pitTitle.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF006100" } };
pitTitle.alignment = { horizontal: "center" };

// ---------------- TIME BREAKDOWN ----------------

worksheet.mergeCells(`J${sectionRow}:N${sectionRow}`);
const timeTitle = worksheet.getCell(`J${sectionRow}`);
timeTitle.value = "Time Breakdown";
timeTitle.font = { bold: true, color: { argb: "FFFFFFFF" } };
timeTitle.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF006100" } };
timeTitle.alignment = { horizontal: "center" };


// ================= HEADER ROW =================

sectionRow++;

worksheet.getRow(sectionRow).values = [
  "Description","Qty.","Cum.","Cost (Kwd)",
  "Pit","Vol (bbl)","Density","Fluid Type","",
  "Rig-up / Service","Hours","","",""
];

worksheet.getRow(sectionRow).eachCell(cell=>{
  cell.font={bold:true};
  cell.alignment={horizontal:"center"};
  cell.border={top:{style:"thin"},left:{style:"thin"},bottom:{style:"thin"},right:{style:"thin"}};
});


// ================= SERVICES DATA =================

let serviceStartRow = sectionRow + 1;

services.forEach(service => {

  const row = worksheet.getRow(serviceStartRow);

  row.values = [
    service.itemName,
    service.qty || 0,
    service.cumulativeUsed || 0,
    service.costDollar || 0
  ];

  row.eachCell(cell=>{
    cell.border={
      top:{style:"thin"},
      left:{style:"thin"},
      bottom:{style:"thin"},
      right:{style:"thin"}
    };
  });

  serviceStartRow++;

});

sectionRow = serviceStartRow;

// ================= ACTIVE PITS DATA =================

let pitRow = sectionRow + 1;

activePits.forEach(pit => {

  const row = worksheet.getRow(pitRow);

  row.getCell(5).value = pit.pitName;
  row.getCell(6).value = pit.volume || pit.capacity;
row.getCell(7).value = pit.density || "";
row.getCell(8).value = pit.fluidType || "";

  for (let c = 5; c <= 8; c++) {
    row.getCell(c).border = {
      top:{style:"thin"},
      left:{style:"thin"},
      bottom:{style:"thin"},
      right:{style:"thin"}
    };
  }

  pitRow++;

});

// IMPORTANT
sectionRow = pitRow;


// =====================================================
// ENGINEERING
// =====================================================

sectionRow++;

worksheet.mergeCells(`A${sectionRow}:D${sectionRow}`);
const engTitle = worksheet.getCell(`A${sectionRow}`);
engTitle.value="Engineering";
engTitle.font={bold:true,color:{argb:"FFFFFFFF"}};
engTitle.fill={type:"pattern",pattern:"solid",fgColor:{argb:"FF006100"}};
engTitle.alignment={horizontal:"center"};

sectionRow++;

worksheet.getRow(sectionRow).values=[
"Description","Qty.","Cum.","Cost (Kwd)"
];

let engRow = sectionRow + 1;

engineers.forEach(engineer => {

  const row = worksheet.getRow(engRow);

  row.values = [
    engineer.itemName,
    engineer.qty || 0,
    engineer.cumulativeUsed || 0,
    engineer.costDollar || 0
  ];

  row.eachCell(cell=>{
    cell.border={
      top:{style:"thin"},
      left:{style:"thin"},
      bottom:{style:"thin"},
      right:{style:"thin"}
    };
  });

  engRow++;

});

sectionRow = engRow;
// ================= RESERVE =================

let reserveRow = engRow + 2;

// Title
worksheet.mergeCells(`E${reserveRow}:H${reserveRow}`);

const reserveTitle = worksheet.getCell(`E${reserveRow}`);

reserveTitle.value = "Reserve";

reserveTitle.font = { bold: true };

reserveTitle.alignment = { horizontal: "center" };

reserveTitle.fill = {
  type: "pattern",
  pattern: "solid",
  fgColor: { argb: "FFEBF1DE" }
};

// Header
reserveRow++;

const reserveHeader = worksheet.getRow(reserveRow);

reserveHeader.getCell(5).value = "Pit";
reserveHeader.getCell(6).value = "Vol (bbl)";
reserveHeader.getCell(7).value = "Density";
reserveHeader.getCell(8).value = "Fluid Type";

for (let c = 5; c <= 8; c++) {

  const cell = reserveHeader.getCell(c);

  cell.font = { bold: true };

  cell.alignment = { horizontal: "center" };

  cell.fill = {
    type: "pattern",
    pattern: "solid",
    fgColor: { argb: "FFE2EFDA" }
  };

  cell.border = {
    top: { style: "thin" },
    left: { style: "thin" },
    bottom: { style: "thin" },
    right: { style: "thin" }
  };

}

// Grid rows

reservePits.forEach(pit => {

  reserveRow++;

  const row = worksheet.getRow(reserveRow);

  row.getCell(5).value = pit.pitName;
  row.getCell(6).value = pit.capacity;
  row.getCell(7).value = "";
  row.getCell(8).value = "";

  for (let c = 5; c <= 8; c++) {
    row.getCell(c).border = {
      top:{style:"thin"},
      left:{style:"thin"},
      bottom:{style:"thin"},
      right:{style:"thin"}
    };
  }

});

// =====================================================
// COST SUMMARY
// =====================================================

sectionRow+=6;

worksheet.mergeCells(`A${sectionRow}:D${sectionRow}`);

const costTitle = worksheet.getCell(`A${sectionRow}`);

costTitle.value="Cost Summary";

costTitle.font={bold:true,color:{argb:"FFFFFFFF"}};

costTitle.fill={
type:"pattern",
pattern:"solid",
fgColor:{argb:"FF006100"}
};

costTitle.alignment={horizontal:"center"};


// =====================================================
// CUTTINGS ANALYSIS
// =====================================================

worksheet.mergeCells(`J${sectionRow}:N${sectionRow}`);

const cutTitle = worksheet.getCell(`J${sectionRow}`);

cutTitle.value="Cuttings Analysis";

cutTitle.font={bold:true,color:{argb:"FFFFFFFF"}};

cutTitle.fill={
type:"pattern",
pattern:"solid",
fgColor:{argb:"FF006100"}
};

cutTitle.alignment={horizontal:"center"};
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
    console.error(error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};