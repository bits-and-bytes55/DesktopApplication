import xlsx from "xlsx";

/**
 * UI ke according EXACT headers
 */
const REQUIRED_HEADERS = [
  "Product",   // Company Brand Name
  "Code",      // Mandatory + Unique
  "SG",        // Decimal
  "Unit Num",  // Number (e.g. 54)
  "Unit Class",// KG / Gal / MT / custom
  "Group",     // Category
  "Retail",    // Yes / No
  "A",
  "B",
  "C",
  "D",
  "E",
  "F"
];

export const parseProductExcel = (filePath) => {
  const workbook = xlsx.readFile(filePath);
  const sheet = workbook.Sheets[workbook.SheetNames[0]];
  const rows = xlsx.utils.sheet_to_json(sheet, { defval: "" });

  // 🔴 Header validation
  const headers = Object.keys(rows[0] || {});
  const missingHeaders = REQUIRED_HEADERS.filter(h => !headers.includes(h));

  if (missingHeaders.length) {
    return {
      success: false,
      type: "HEADER_ERROR",
      message: "Excel headers do not match UI fields",
      missingHeaders
    };
  }

  const valid = [];
  const errors = [];
  const duplicateMap = new Set(); // Excel-level duplicate check

  rows.forEach((r, index) => {
    const rowNumber = index + 2;

    // 🔴 Empty row ignore
    if (!r["Product"] || !r["Code"]) return;

    // 🔴 Excel-level duplicate (Code based)
    if (duplicateMap.has(r["Code"])) {
      errors.push({
        row: rowNumber,
        type: "DUPLICATE_IN_EXCEL",
        message: "Duplicate Code found in Excel",
        field: "Code"
      });
      return;
    }
    duplicateMap.add(r["Code"]);

    // 🔴 Required field validation
    const missingFields = [];

    if (!r["Product"]) missingFields.push("Product");
    if (!r["Code"]) missingFields.push("Code");
    if (r["SG"] === "") missingFields.push("SG");
    if (!r["Unit Num"]) missingFields.push("Unit Num");
    if (!r["Unit Class"]) missingFields.push("Unit Class");
    if (!r["Group"]) missingFields.push("Group");

    if (missingFields.length) {
      errors.push({
        row: rowNumber,
        type: "VALIDATION_ERROR",
        message: "Required fields missing",
        fields: missingFields
      });
      return;
    }

    // ✅ Valid row → UI-aligned structure
    valid.push({
      Product: r["Product"].trim(),
      Code: r["Code"].trim(),
      SG: Number(r["SG"]),
      Unit: {
        Num: Number(r["Unit Num"]),
        Class: r["Unit Class"].trim()
      },
      Group: r["Group"].trim(),
      Retail: r["Retail"] === "Yes" ? "Yes" : "No",
      A: r["A"] !== "" ? Number(r["A"]) : undefined,
      B: r["B"] !== "" ? Number(r["B"]) : undefined,
      C: r["C"] !== "" ? Number(r["C"]) : undefined,
      D: r["D"] !== "" ? Number(r["D"]) : undefined,
      E: r["E"] !== "" ? Number(r["E"]) : undefined,
      F: r["F"] !== "" ? Number(r["F"]) : undefined
    });
  });

  return {
    success: true,
    valid,
    errors
  };
};
