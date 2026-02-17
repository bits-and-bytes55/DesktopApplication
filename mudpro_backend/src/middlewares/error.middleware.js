import multer from "multer";
import path from "path";
import fs from "fs";

const uploadDir = "src/temp/uploads";

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: uploadDir,
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});

const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  if (ext === ".xlsx" || ext === ".xls") {
    cb(null, true);
  } else {
    cb(new Error("Only Excel files allowed"));
  }
};

export const uploadExcel = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10 MB
  }
});


// globle error handling middleware for product routes
export const errorHandler = (err, req, res, next) => {
  console.error("❌ ERROR:", err.message);

  // Multer errors
  if (err.code === "LIMIT_FILE_SIZE") {
    return res.status(400).json({
      success: false,
      message: "File size exceeds 10MB limit"
    });
  }

  // Mongo duplicate key
  if (err.code === 11000) {
    return res.status(409).json({
      success: false,
      message: "Duplicate product detected"
    });
  }

  res.status(500).json({
    success: false,
    message: err.message || "Internal Server Error"
  });
};
