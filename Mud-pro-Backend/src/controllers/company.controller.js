import Company from "../modules/company/company.model.js";
import multer, { diskStorage } from "multer";
import { extname as _extname } from "path";

// 🔹 Configure Multer for Image Upload
const storage = diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/company-logos/"); // Make sure this folder exists
  },
  filename: (req, file, cb) => {
    const uniqueName = `company-logo-${Date.now()}${_extname(file.originalname)}`;
    cb(null, uniqueName);
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(_extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (extname && mimetype) {
      cb(null, true);
    } else {
      cb(new Error("Only image files are allowed (jpeg, jpg, png, gif)"));
    }
  },
});

// 🔹 GET Company Details
export async function getCompany(req, res) {
  try {
    const company = await findOne();
    res.json({
      success: true,
      data: company,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
}

// 🔹 SAVE / UPDATE Company Details with Image
export async function saveCompany(req, res) {
  try {
    console.log("📌 Request body:", req.body);
    console.log("📌 Uploaded file:", req.file);

    // Check if company already exists
    let company = await findOne();
    
    const data = {
      companyName: req.body.companyName,
      address: req.body.address,
      phone: req.body.phone,
      email: req.body.email,
      currencySymbol: req.body.currencySymbol || "₹",
      currencyFormat: req.body.currencyFormat || "0.00",
    };

    // If new image is uploaded, add logo URL
    if (req.file) {
      data.logoUrl = `/uploads/company-logos/${req.file.filename}`;
      console.log("📌 Logo saved at:", data.logoUrl);
    } else if (company && company.logoUrl) {
      // Keep existing logo if no new file uploaded
      data.logoUrl = company.logoUrl;
    }

    if (company) {
      // Update existing company
      Object.assign(company, data);
      await company.save();
      console.log("✅ Company updated");
    } else {
      // Create new company
      company = new Company(data);
      await company.save();
      console.log("✅ New company created");
    }

    res.json({
      success: true,
      message: "Company details saved successfully",
      data: company,
    });
  } catch (err) {
    console.error("❌ Error saving company:", err);
    res.status(500).json({
      success: false,
      message: err.message || "Failed to save company details",
    });
  }
}

// 🔹 UPDATE Company Details with Image
export async function updateCompany(req, res) {
  try {
    console.log("📌 Update request body:", req.body);
    console.log("📌 Update file:", req.file);

    // Get existing company first
    const existingCompany = await findOne();
    
    if (!existingCompany) {
      return res.status(404).json({
        success: false,
        message: "Company not found",
      });
    }
    
    // Update fields
    existingCompany.companyName = req.body.companyName || existingCompany.companyName;
    existingCompany.address = req.body.address || existingCompany.address;
    existingCompany.phone = req.body.phone || existingCompany.phone;
    existingCompany.email = req.body.email || existingCompany.email;
    existingCompany.currencySymbol = req.body.currencySymbol || existingCompany.currencySymbol;
    existingCompany.currencyFormat = req.body.currencyFormat || existingCompany.currencyFormat;

    // If new image is uploaded, update logo URL
    if (req.file) {
      existingCompany.logoUrl = `/uploads/company-logos/${req.file.filename}`;
      console.log("📌 New logo saved at:", existingCompany.logoUrl);
    }

    await existingCompany.save();
    console.log("✅ Company updated successfully");

    res.json({
      success: true,
      message: "Company details updated successfully",
      data: existingCompany,
    });
  } catch (error) {
    console.error("❌ Error updating company:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Failed to update company details",
    });
  }
}

export const uploadLogo = upload.single("logo");