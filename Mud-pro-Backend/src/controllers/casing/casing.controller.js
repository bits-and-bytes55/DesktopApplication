import Casing from '../../modules/casing/casing.model.js';

export const getAllCasings = async (req, res) => {
  try {
    const casings = await Casing.find().sort({ createdAt: 1 });
    res.status(200).json({ success: true, data: casings });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const addCasing = async (req, res) => {
  try {
    const newCasing = new Casing(req.body);
    const savedCasing = await newCasing.save();
    res.status(201).json({ success: true, data: savedCasing });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const updateCasing = async (req, res) => {
  try {
    const updatedCasing = await Casing.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    if (!updatedCasing) {
      return res.status(404).json({ success: false, message: 'Casing not found' });
    }
    res.status(200).json({ success: true, data: updatedCasing });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const deleteCasing = async (req, res) => {
  try {
    const deletedCasing = await Casing.findByIdAndDelete(req.params.id);
    if (!deletedCasing) {
      return res.status(404).json({ success: false, message: 'Casing not found' });
    }
    res.status(200).json({ success: true, message: 'Casing deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
