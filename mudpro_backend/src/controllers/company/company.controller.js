import Company from "../../modules/company/company.model.js";
import cloudinary from "../../config/cloudinary.js";

// 🔹 GET company
export async function getCompany(req, res) {
  try {
    const company = await Company.findOne();
    res.json({ success: true, data: company });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

// 🔹 ADD / UPDATE company
export async function saveCompany(req, res) {
  try {
    const {
      companyName,
      address,
      phone,
      email,
      currencySymbol,
      currencyFormat,
      logoBase64, // 👈 base64 image string
    } = req.body;

    if (!companyName || !address || !phone || !email) {
      return res.status(400).json({
        success: false,
        message: "Required fields missing",
      });
    }

    let company = await Company.findOne(); // ✅ FIXED

    let logoUrl = company?.logoUrl;

    // 🔹 Upload image to Cloudinary
    if (logoBase64) {
      const uploadRes = await cloudinary.uploader.upload(logoBase64, {
        folder: "mudpro/company",
      });
      logoUrl = uploadRes.secure_url;
    }

    if (company) {
      // update
      Object.assign(company, {
        companyName,
        address,
        phone,
        email,
        currencySymbol,
        currencyFormat,
        logoUrl,
      });
      await company.save();
    } else {
      // create
      company = await Company.create({
        companyName,
        address,
        phone,
        email,
        currencySymbol,
        currencyFormat,
        logoUrl,
      });
    }

    res.json({
      success: true,
      message: "Company saved successfully",
      data: company,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
}
