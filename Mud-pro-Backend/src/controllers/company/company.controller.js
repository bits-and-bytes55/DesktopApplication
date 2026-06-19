import Company from "../../modules/company/company.model.js";
import cloudinary from "../../config/cloudinary.js";






// 🔹 GET Company
export async function getCompany(req, res) {
  try {
    const company = await Company.findOne();
    res.json({ success: true, data: company });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

export async function saveCompany(req, res) {
  try {
    const {
      companyName,
      address,
      phone,
      email,
      currencySymbol,
      currencyFormat,
      logoBase64,
    } = req.body;

    if (!companyName || !address || !phone || !email) {
      return res.status(400).json({
        success: false,
        message: "Required fields missing",
      });
    }

    let company = await Company.findOne();

    let logoUrl = company?.logoUrl || null;
    let logoPublicId = company?.logoPublicId || null;

    // =============================
    // Upload New Logo
    // =============================
    if (logoBase64) {
      // delete old logo if exists
      if (logoPublicId) {
        await cloudinary.uploader.destroy(logoPublicId);
      }

      const uploadRes = await cloudinary.uploader.upload(logoBase64, {
        folder: "mudpro/company",
      });

      logoUrl = uploadRes.secure_url;
      logoPublicId = uploadRes.public_id;
    }

    if (company) {
      // update
      company.companyName = companyName;
      company.address = address;
      company.phone = phone;
      company.email = email;
      company.currencySymbol = currencySymbol;
      company.currencyFormat = currencyFormat;
      company.logoUrl = logoUrl;
      company.logoPublicId = logoPublicId;

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
        logoPublicId,
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
