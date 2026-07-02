import Engineer from "../../modules/engineers/engineer.model.js";

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
}

// ✅ PUT: Update engineer
export async function updateEngineer(req, res) {
  try {
    const { id } = req.params;
    const engineer = await Engineer.findByIdAndUpdate(
      id,
      req.body,
      { returnDocument: "after", runValidators: true }
    );
    
    if (!engineer) {
      return res.status(404).json({
        success: false,
        message: "Engineer not found",
      });
    }
    
    res.json({
      success: true,
      data: engineer,
      message: "Engineer updated successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
}

// ✅ DELETE: Delete engineer
export async function deleteEngineer(req, res) {
  try {
    const { id } = req.params;
    const engineer = await Engineer.findByIdAndDelete(id);
    
    if (!engineer) {
      return res.status(404).json({
        success: false,
        message: "Engineer not found",
      });
    }
    
    res.json({
      success: true,
      message: "Engineer deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
}