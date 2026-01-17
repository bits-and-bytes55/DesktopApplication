const Company = require("./company.model");

// 🔹 GET Company Details
exports.getCompany = async (req, res) => {
  try {
    const company = await Company.findOne();
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
};

// 🔹 SAVE / UPDATE Company Details
exports.saveCompany = async (req, res) => {
  try {
    const data = req.body;

    const company = await Company.findOneAndUpdate(
      {},            // single record
      data,          // new data
      { new: true, upsert: true }
    );

    res.json({
      success: true,
      message: "Company details saved",
      data: company,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
};


// 🔹 UPDATE Company Details
exports.updateCompany = async (req, res) => {
  try {
    const updatedCompany = await Company.findOneAndUpdate(
      {},               // kyunki sirf ek hi company hoti hai
      { $set: req.body },
      { new: true }     // updated data return kare
    );

    if (!updatedCompany) {
      return res.status(404).json({
        success: false,
        message: "Company not found",
      });
    }

    res.json({
      success: true,
      message: "Company details updated successfully",
      data: updatedCompany,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
