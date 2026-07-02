import { Service } from "../../modules/service/services.model.js";

// CREATE SINGLE
export const createService = async (req, res) => {
  try {
    const data = await Service.create(req.body);
    res.status(201).json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// CREATE BULK (NEW)
export const createBulkServices = async (req, res) => {
  try {
    const services = req.body; // Array of services
    
    if (!Array.isArray(services) || services.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: "Please provide an array of services" 
      });
    }

    const data = await Service.insertMany(services);
    res.status(201).json({ 
      success: true, 
      data, 
      saved: data.length,
      message: `${data.length} services added successfully`
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET ALL
export const getServices = async (req, res) => {
  try {
    const data = await Service.find().sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// UPDATE
export const updateService = async (req, res) => {
  try {
    const data = await Service.findByIdAndUpdate(
      req.params.id,
      req.body,
      { returnDocument: "after" }
    );
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// DELETE
export const deleteService = async (req, res) => {
  try {
    await Service.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: "Service deleted" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};