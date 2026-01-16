const Engineer = require("./engineer.model");

// ✅ POST: Save engineer
exports.createEngineer = async (req, res) => {
  try {
    const engineer = await Engineer.create(req.body);
    res.status(201).json({
      success: true,
      data: engineer,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ✅ GET: All engineers (for dropdown)
exports.getEngineers = async (req, res) => {
  try {
    const engineers = await Engineer.find().sort({ firstName: 1 });
    res.json({
      success: true,
      data: engineers,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
