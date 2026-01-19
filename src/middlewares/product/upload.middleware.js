import multer from "multer";
import path from "path";
import fs from "fs";

// Temp upload directory
const UPLOAD_DIR = "src/temp/uploads";

// Ensure temp directory exists
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

// Storage config
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, UPLOAD_DIR);
  },
  filename: (req, file, cb) => {
    const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, uniqueName + path.extname(file.originalname));
  }
});

// File type validation
const fileFilter = (req, file, cb) => {
  const allowedTypes = [".xlsx", ".xls"];
  const ext = path.extname(file.originalname).toLowerCase();

  if (!allowedTypes.includes(ext)) {
    cb(new Error("Only Excel files (.xlsx, .xls) are allowed"));
  } else {
    cb(null, true);
  }
};

export const uploadExcel = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10 MB
  }
});
