import WellGeneral from "../../modules/wellGeneral/wellGeneralModel.js";

// Create
export const createWellGeneral = async (req, res) => {
  try {
    const data = await WellGeneral.create(req.body);
    res.status(201).json({ success: true, message: "Well General created", data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get all
export const getWellGenerals = async (req, res) => {
  try {
    const data = await WellGeneral.find().sort({ createdAt: -1 });
    res.status(200).json({ success: true, count: data.length, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get by id
export const getWellGeneralById = async (req, res) => {
  try {
    const data = await WellGeneral.findById(req.params.id);
    if (!data) return res.status(404).json({ success: false, message: "Not found" });
    res.status(200).json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Update
export const updateWellGeneral = async (req, res) => {
  try {
    const data = await WellGeneral.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!data) return res.status(404).json({ success: false, message: "Not found" });
    res.status(200).json({ success: true, message: "Updated", data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Delete
export const deleteWellGeneral = async (req, res) => {
  try {
    await WellGeneral.findByIdAndDelete(req.params.id);
    res.status(200).json({ success: true, message: "Deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};