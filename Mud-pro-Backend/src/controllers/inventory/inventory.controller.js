import Premixed from '../../modules/inventory/premixed.model.js';
import Obm from '../../modules/inventory/obm.model.js';

// ==================== PREMIXED CONTROLLERS ====================

// Get all premixed for a well
export const getPremixed = async (req, res) => {
  try {
    const { wellId } = req.params;
    
    const premixedList = await Premixed.find({ wellId })
      .sort({ createdAt: 1 });
    
    res.status(200).json({
      success: true,
      data: premixedList
    });
  } catch (error) {
    console.error('Error fetching premixed:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch premixed data',
      error: error.message
    });
  }
};

// Create new premixed
export const createPremixed = async (req, res) => {
  try {
    const { wellId } = req.params;
    const { description, mw, leasingFee, mudType, tax } = req.body;
    
    // Validation
    if (!description || !mw || !leasingFee || !mudType) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required'
      });
    }
    
    const newPremixed = new Premixed({
      description,
      mw,
      leasingFee,
      mudType,
      tax: tax || false,
      wellId
    });
    
    await newPremixed.save();
    
    res.status(201).json({
      success: true,
      message: 'Premixed created successfully',
      data: newPremixed
    });
  } catch (error) {
    console.error('Error creating premixed:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create premixed',
      error: error.message
    });
  }
};

// Update premixed
export const updatePremixed = async (req, res) => {
  try {
    const { id } = req.params;
    const { description, mw, leasingFee, mudType, tax } = req.body;
    
    const updatedPremixed = await Premixed.findByIdAndUpdate(
      id,
      {
        description,
        mw,
        leasingFee,
        mudType,
        tax,
        updatedAt: Date.now()
      },
      { new: true, runValidators: true }
    );
    
    if (!updatedPremixed) {
      return res.status(404).json({
        success: false,
        message: 'Premixed not found'
      });
    }
    
    res.status(200).json({
      success: true,
      message: 'Premixed updated successfully',
      data: updatedPremixed
    });
  } catch (error) {
    console.error('Error updating premixed:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update premixed',
      error: error.message
    });
  }
};

// Delete premixed
export const deletePremixed = async (req, res) => {
  try {
    const { id } = req.params;
    
    const deletedPremixed = await Premixed.findByIdAndDelete(id);
    
    if (!deletedPremixed) {
      return res.status(404).json({
        success: false,
        message: 'Premixed not found'
      });
    }
    
    res.status(200).json({
      success: true,
      message: 'Premixed deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting premixed:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete premixed',
      error: error.message
    });
  }
};

// ==================== OBM CONTROLLERS ====================

// Get all OBM for a well
export const getObm = async (req, res) => {
  try {
    const { wellId } = req.params;
    
    const obmList = await Obm.find({ wellId })
      .sort({ createdAt: 1 });
    
    res.status(200).json({
      success: true,
      data: obmList
    });
  } catch (error) {
    console.error('Error fetching OBM:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch OBM data',
      error: error.message
    });
  }
};

// Create new OBM
export const createObm = async (req, res) => {
  try {
    const { wellId } = req.params;
    const { product, code, sg, conc, unit } = req.body;
    
    // Validation
    if (!product || !code || !sg || !conc) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required'
      });
    }
    
    const newObm = new Obm({
      product,
      code,
      sg,
      conc,
      unit: unit ?? '',
      wellId
    });
    
    await newObm.save();
    
    res.status(201).json({
      success: true,
      message: 'OBM created successfully',
      data: newObm
    });
  } catch (error) {
    console.error('Error creating OBM:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create OBM',
      error: error.message
    });
  }
};

// Update OBM
export const updateObm = async (req, res) => {
  try {
    const { id } = req.params;
    const { product, code, sg, conc, unit } = req.body;
    
    const updatedObm = await Obm.findByIdAndUpdate(
      id,
      {
        product,
        code,
        sg,
        conc,
        unit: unit ?? '',
        updatedAt: Date.now()
      },
      { new: true, runValidators: true }
    );
    
    if (!updatedObm) {
      return res.status(404).json({
        success: false,
        message: 'OBM not found'
      });
    }
    
    res.status(200).json({
      success: true,
      message: 'OBM updated successfully',
      data: updatedObm
    });
  } catch (error) {
    console.error('Error updating OBM:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update OBM',
      error: error.message
    });
  }
};

// Delete OBM
export const deleteObm = async (req, res) => {
  try {
    const { id } = req.params;
    
    const deletedObm = await Obm.findByIdAndDelete(id);
    
    if (!deletedObm) {
      return res.status(404).json({
        success: false,
        message: 'OBM not found'
      });
    }
    
    res.status(200).json({
      success: true,
      message: 'OBM deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting OBM:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete OBM',
      error: error.message
    });
  }
};
