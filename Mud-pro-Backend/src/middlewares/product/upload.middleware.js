import multer from "multer";
import path from "path";
import fs from "fs";

/* =========================================
   TEMP DIRECTORY (Excel Uploads Only)
========================================= */
const UPLOAD_DIR = "src/temp/uploads/excel";

// Ensure temp directory exists
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

/* =========================================
   STORAGE CONFIG
========================================= */
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, UPLOAD_DIR);
  },
  filename: (req, file, cb) => {
    const uniqueName = `excel-${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, uniqueName + path.extname(file.originalname));
  }
});

/* =========================================
   FILE VALIDATION (STRICT)
========================================= */
const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = [
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", // .xlsx
    "application/vnd.ms-excel" // .xls
  ];

  const ext = path.extname(file.originalname).toLowerCase();

  if (
    !allowedMimeTypes.includes(file.mimetype) ||
    ![".xlsx", ".xls"].includes(ext)
  ) {
    return cb(
      new Error("Invalid file type. Only Excel files (.xlsx, .xls) are allowed"),
      false
    );
  }

  cb(null, true);
};

/* =========================================
   MULTER INSTANCE
========================================= */
export const uploadExcel = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10 MB max
  }
});
