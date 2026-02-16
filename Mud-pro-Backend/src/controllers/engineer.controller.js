import Engineer from "../modules/engineers/engineer.model.js";

// ✅ POST: Save engineer
export async function createEngineer(req, res) {
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
}

// ✅ GET: All engineers (for dropdown)
export async function getEngineers(req, res) {
  try {
    const engineers = await find().sort({ firstName: 1 });
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
}

