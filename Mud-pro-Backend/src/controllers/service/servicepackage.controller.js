import { Package } from "../../modules/service/services.model.js";

// CREATE SINGLE
export const createPackage = async (req, res) => {
  try {
    console.log("Creating package:", req.body);
    const data = await Package.create(req.body);
    res.status(201).json({ success: true, data });
  } catch (err) {
    console.error("Error creating package:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// CREATE BULK
export const createBulkPackages = async (req, res) => {
  try {
    const packages = req.body;
    console.log("Creating bulk packages:", packages);
    
    if (!Array.isArray(packages) || packages.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: "Please provide an array of packages" 
      });
    }

    const data = await Package.insertMany(packages);
    res.status(201).json({ 
      success: true, 
      data, 
      saved: data.length,
      message: `${data.length} packages added successfully`
    });
  } catch (err) {
    console.error("Error creating bulk packages:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET ALL
export const getPackages = async (req, res) => {
  try {
    const data = await Package.find().sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (err) {
    console.error("Error getting packages:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// UPDATE
export const updatePackage = async (req, res) => {
  try {
    console.log("Updating package:", req.params.id, req.body);
    const data = await Package.findByIdAndUpdate(
      req.params.id,
      req.body,
      { returnDocument: "after", runValidators: true }
    );
    
    if (!data) {
      return res.status(404).json({ 
        success: false, 
        message: "Package not found" 
      });
    }
    
    res.json({ success: true, data, message: "Package updated successfully" });
  } catch (err) {
    console.error("Error updating package:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// DELETE
export const deletePackage = async (req, res) => {
  try {
    console.log("Deleting package:", req.params.id);
    const data = await Package.findByIdAndDelete(req.params.id);
    
    if (!data) {
      return res.status(404).json({ 
        success: false, 
        message: "Package not found" 
      });
    }
    
    res.json({ success: true, message: "Package deleted successfully" });
  } catch (err) {
    console.error("Error deleting package:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};