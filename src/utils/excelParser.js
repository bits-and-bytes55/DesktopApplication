import xlsx from "xlsx";

const REQUIRED_HEADERS = [
  "Company Brand name",
  "Size",
  "Unit",
  "Packaging",
  "Density S.G.",
  "Product Category"
];

export const parseProductExcel = (filePath) => {
  const workbook = xlsx.readFile(filePath);
  const sheet = workbook.Sheets[workbook.SheetNames[0]];
  const rows = xlsx.utils.sheet_to_json(sheet, { defval: "" });

  const headers = Object.keys(rows[0] || {});
  const missingHeaders = REQUIRED_HEADERS.filter(h => !headers.includes(h));

  if (missingHeaders.length) {
    throw {
      type: "HEADER_ERROR",
      message: "Invalid Excel format",
      missingHeaders
    };
  }

  const valid = [];
  const errors = [];

  rows.forEach((r, index) => {
    if (!r["Company Brand name"]) return;

    const rowData = {
      companyBrandName: r["Company Brand name"].trim(),
      sizeValue: Number(r["Size"]),
      sizeUnit: r["Unit"],
      packagingType: r["Packaging"],
      densitySG: Number(r["Density S.G."]),
      productCategory: r["Product Category"]
    };

    const hasError = Object.values(rowData).some(v => !v);

    if (hasError) {
      errors.push({ row: index + 2, data: rowData });
    } else {
      valid.push(rowData);
    }
  });

  return { valid, errors };
};
