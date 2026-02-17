import { Engineering } from "../../modules/service/services.model.js";

// CREATE SINGLE
export const createEngineering = async (req, res) => {
  try {
    
    console.log("Creating engineering:", req.body);
    const data = await Engineering.create(req.body);
    res.status(201).json({ success: true, data });
  } catch (err) {
    console.error("Error creating engineering:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// CREATE BULK
export const createBulkEngineering = async (req, res) => {
  try {
    const engineering = req.body;
    console.log("Creating bulk engineering:", engineering);
    
    if (!Array.isArray(engineering) || engineering.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: "Please provide an array of engineering items" 
      });
    }

    const data = await Engineering.insertMany(engineering);
    res.status(201).json({ 
      success: true, 
      data, 
      saved: data.length,
      message: `${data.length} engineering items added successfully`
    });
  } catch (err) {
    console.error("Error creating bulk engineering:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET ALL
export const getEngineering = async (req, res) => {
  try {
    const data = await Engineering.find().sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (err) {
    console.error("Error getting engineering:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// UPDATE
export const updateEngineering = async (req, res) => {
  try {
    console.log("Updating engineering:", req.params.id, req.body);
    const data = await Engineering.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    
    if (!data) {
      return res.status(404).json({ 
        success: false, 
        message: "Engineering not found" 
      });
    }
    
    res.json({ success: true, data, message: "Engineering updated successfully" });
  } catch (err) {
    console.error("Error updating engineering:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// DELETE
export const deleteEngineering = async (req, res) => {
  try {
     console.log("🔴 DELETE Engineering Request");
    console.log("🔴 ID:", req.params.id);
    console.log("🔴 Full URL:", req.originalUrl);
    console.log("Deleting engineering:", req.params.id);
    const data = await Engineering.findByIdAndDelete(req.params.id);
    
    if (!data) {
       console.log("🔴 Engineering not found!");
      return res.status(404).json({ 
        success: false, 
        message: "Engineering not found" 
      });
    }
    
    console.log("✅ Engineering deleted:", data);
    res.json({ success: true, message: "Engineering deleted successfully" });
  } catch (err) {
    console.error("Error deleting engineering:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};