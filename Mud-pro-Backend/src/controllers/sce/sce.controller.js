import { Shaker, OtherSce } from '../../modules/sce/sce.model.js';
import mongoose from 'mongoose';

// ==================== SHAKER CONTROLLERS ====================

// Get all shakers for a well
export const getShakers = async (req, res) => {
  try {
    const { wellId } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(wellId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid well ID'
      });
    }

    const shakers = await Shaker.find({ wellId }).sort({ createdAt: 1 });
    
    res.status(200).json({
      success: true,
      data: shakers,
      count: shakers.length
    });
  } catch (error) {
    console.error('Error fetching shakers:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch shakers',
      error: error.message
    });
  }
};

// Create a new shaker
export const createShaker = async (req, res) => {
  try {
    const { wellId } = req.params;
    const { shaker, model, screens, plot } = req.body;

    if (!mongoose.Types.ObjectId.isValid(wellId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid well ID'
      });
    }

    if (!shaker) {
      return res.status(400).json({
        success: false,
        message: 'Shaker name is required'
      });
    }

    const newShaker = new Shaker({
      wellId,
      shaker,
      model: model || '',
      screens: screens || '',
      plot: plot || false
    });

    await newShaker.save();

    res.status(201).json({
      success: true,
      message: 'Shaker created successfully',
      data: newShaker
    });
  } catch (error) {
    console.error('Error creating shaker:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create shaker',
      error: error.message
    });
  }
};

// Update a shaker
export const updateShaker = async (req, res) => {
  try {
    const { id } = req.params;
    const { shaker, model, screens, plot } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid shaker ID'
      });
    }

    const updatedShaker = await Shaker.findByIdAndUpdate(
      id,
      {
        ...(shaker !== undefined && { shaker }),
        ...(model !== undefined && { model }),
        ...(screens !== undefined && { screens }),
        ...(plot !== undefined && { plot })
      },
      { new: true, runValidators: true }
    );

    if (!updatedShaker) {
      return res.status(404).json({
        success: false,
        message: 'Shaker not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Shaker updated successfully',
      data: updatedShaker
    });
  } catch (error) {
    console.error('Error updating shaker:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update shaker',
      error: error.message
    });
  }
};

// Delete a shaker
export const deleteShaker = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid shaker ID'
      });
    }

    const deletedShaker = await Shaker.findByIdAndDelete(id);

    if (!deletedShaker) {
      return res.status(404).json({
        success: false,
        message: 'Shaker not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Shaker deleted successfully',
      data: deletedShaker
    });
  } catch (error) {
    console.error('Error deleting shaker:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete shaker',
      error: error.message
    });
  }
};

// ==================== OTHER SCE CONTROLLERS ====================

// Get all other SCE for a well
export const getOtherSce = async (req, res) => {
  try {
    const { wellId } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(wellId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid well ID'
      });
    }

    const otherSce = await OtherSce.find({ wellId }).sort({ createdAt: 1 });
    
    res.status(200).json({
      success: true,
      data: otherSce,
      count: otherSce.length
    });
  } catch (error) {
    console.error('Error fetching other SCE:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch other SCE',
      error: error.message
    });
  }
};

// Create a new other SCE
export const createOtherSce = async (req, res) => {
  try {
    const { wellId } = req.params;
    const { type, model1, model2, model3, plot } = req.body;

    if (!mongoose.Types.ObjectId.isValid(wellId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid well ID'
      });
    }

    if (!type) {
      return res.status(400).json({
        success: false,
        message: 'Type is required'
      });
    }

    const newOtherSce = new OtherSce({
      wellId,
      type,
      model1: model1 || '',
      model2: model2 || '',
      model3: model3 || '',
      plot: plot || false
    });

    await newOtherSce.save();

    res.status(201).json({
      success: true,
      message: 'Other SCE created successfully',
      data: newOtherSce
    });
  } catch (error) {
    console.error('Error creating other SCE:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create other SCE',
      error: error.message
    });
  }
};

// Update an other SCE
export const updateOtherSce = async (req, res) => {
  try {
    const { id } = req.params;
    const { type, model1, model2, model3, plot } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid other SCE ID'
      });
    }

    const updatedOtherSce = await OtherSce.findByIdAndUpdate(
      id,
      {
        ...(type !== undefined && { type }),
        ...(model1 !== undefined && { model1 }),
        ...(model2 !== undefined && { model2 }),
        ...(model3 !== undefined && { model3 }),
        ...(plot !== undefined && { plot })
      },
      { new: true, runValidators: true }
    );

    if (!updatedOtherSce) {
      return res.status(404).json({
        success: false,
        message: 'Other SCE not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Other SCE updated successfully',
      data: updatedOtherSce
    });
  } catch (error) {
    console.error('Error updating other SCE:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update other SCE',
      error: error.message
    });
  }
};

// Delete an other SCE
export const deleteOtherSce = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid other SCE ID'
      });
    }

    const deletedOtherSce = await OtherSce.findByIdAndDelete(id);

    if (!deletedOtherSce) {
      return res.status(404).json({
        success: false,
        message: 'Other SCE not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Other SCE deleted successfully',
      data: deletedOtherSce
    });
  } catch (error) {
    console.error('Error deleting other SCE:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete other SCE',
      error: error.message
    });
  }
};