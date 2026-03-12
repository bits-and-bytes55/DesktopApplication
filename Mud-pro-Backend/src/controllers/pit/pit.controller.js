import Pit from '../../modules/pit/pit.model.js';

// ============= CREATE OPERATIONS =============

// Add single pit
// Add single pit - validation update
export const addPit = async (req, res) => {
  try {
    const { pitName, capacity, initialActive, wellId, reportId } = req.body;

    // ✅ BETTER VALIDATION
    if (!pitName || !pitName.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Pit name is required'
      });
    }

    if (capacity === undefined || capacity === null || isNaN(capacity)) {
      return res.status(400).json({
        success: false,
        message: 'Valid capacity is required'
      });
    }

    if (!wellId || !wellId.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Well ID is required'
      });
    }

    // Check if pit already exists (only if not locked)
    const existingPit = await Pit.findOne({ 
      pitName: pitName.trim(), 
      wellId: wellId.trim(),
      isLocked: false 
    });

    if (existingPit) {
      return res.status(409).json({
        success: false,
        message: 'Pit with this name already exists for this well'
      });
    }

    const pit = new Pit({
      pitName: pitName.trim(),
      capacity: Number(capacity),
      initialActive: Boolean(initialActive),
      wellId: wellId.trim(),
      reportId: reportId?.trim(),
      isLocked: false
    });

    await pit.save();

    res.status(201).json({
      success: true,
      message: 'Pit added successfully',
      data: pit
    });
  } catch (error) {
    console.error('Add Pit Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add pit',
      error: error.message
    });
  }
};

// Bulk add pits
export const bulkAddPits = async (req, res) => {
  try {
    const { pits, wellId } = req.body;

    if (!Array.isArray(pits) || pits.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Pits array is required and cannot be empty'
      });
    }

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: 'wellId is required'
      });
    }

    // Filter out existing locked pits
    const pitNames = pits.map(p => p.pitName);
    const existingPits = await Pit.find({
      pitName: { $in: pitNames },
      wellId,
      isLocked: false
    });

    const existingNames = new Set(existingPits.map(p => p.pitName));
    
    // Only add new pits (not already in DB)
    const newPits = pits
      .filter(p => !existingNames.has(p.pitName))
      .map(p => ({
        pitName: p.pitName,
        capacity: p.capacity,
        initialActive: p.initialActive || false,
        wellId,
        reportId: p.reportId,
        isLocked: false
      }));

    if (newPits.length === 0) {
      return res.status(409).json({
        success: false,
        message: 'All pits already exist in the database'
      });
    }

    const insertedPits = await Pit.insertMany(newPits);

    res.status(201).json({
      success: true,
      message: `${insertedPits.length} pits added successfully`,
      data: insertedPits,
      skipped: pits.length - insertedPits.length
    });
  } catch (error) {
    console.error('Bulk Add Pits Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add pits',
      error: error.message
    });
  }
};

// ============= READ OPERATIONS =============

// Get all pits for a well
export const getAllPits = async (req, res) => {
  try {
    const { wellId } = req.params;

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: 'wellId is required'
      });
    }

    const pits = await Pit.find({ wellId }).sort({ createdAt: 1 });

    const totalCapacity = pits.reduce((sum, pit) => sum + pit.capacity, 0);

    res.status(200).json({
      success: true,
      data: pits,
      totalCapacity,
      count: pits.length
    });
  } catch (error) {
    console.error('Get All Pits Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch pits',
      error: error.message
    });
  }
};

// Get selected (active) pits
export const getSelectedPits = async (req, res) => {
  try {
    const { wellId } = req.params;

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: 'wellId is required'
      });
    }

    const selectedPits = await Pit.find({ 
      wellId, 
      initialActive: true 
    }).sort({ createdAt: 1 });

    const totalCapacity = selectedPits.reduce((sum, pit) => sum + pit.capacity, 0);

    res.status(200).json({
      success: true,
      data: selectedPits,
      totalCapacity,
      count: selectedPits.length
    });
  } catch (error) {
    console.error('Get Selected Pits Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch selected pits',
      error: error.message
    });
  }
};

// Get unselected (inactive) pits storage waali
export const getUnselectedPits = async (req, res) => {
  try {
    const { wellId } = req.params;

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: 'wellId is required'
      });
    }

    const unselectedPits = await Pit.find({ 
      wellId, 
      initialActive: false 
    }).sort({ createdAt: 1 });

    const totalCapacity = unselectedPits.reduce((sum, pit) => sum + pit.capacity, 0);

    res.status(200).json({
      success: true,
      data: unselectedPits,
      totalCapacity,
      count: unselectedPits.length
    });
  } catch (error) {
    console.error('Get Unselected Pits Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch unselected pits',
      error: error.message
    });
  }
};

// Get single pit by ID
export const getPitById = async (req, res) => {
  try {
    const { id } = req.params;

    const pit = await Pit.findById(id);

    if (!pit) {
      return res.status(404).json({
        success: false,
        message: 'Pit not found'
      });
    }

    res.status(200).json({
      success: true,
      data: pit
    });
  } catch (error) {
    console.error('Get Pit By ID Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch pit',
      error: error.message
    });
  }
};

// ============= UPDATE OPERATIONS =============

// Update single pit
export const updatePit = async (req, res) => {
  try {
    const { id } = req.params;
   const { pitName, capacity, initialActive, volume, density, fluidType } = req.body;

    const pit = await Pit.findById(id);

    if (!pit) {
      return res.status(404).json({
        success: false,
        message: 'Pit not found'
      });
    }

    // Check if pit is locked
    if (pit.isLocked) {
      return res.status(403).json({
        success: false,
        message: 'Cannot update locked pit'
      });
    }

    // Update fields
    if (pitName) pit.pitName = pitName;
    if (capacity !== undefined) pit.capacity = capacity;
    if (initialActive !== undefined) pit.initialActive = initialActive;
    if (volume !== undefined) pit.volume = volume;
if (density !== undefined) pit.density = density;
if (fluidType !== undefined) pit.fluidType = fluidType;

    await pit.save();

    res.status(200).json({
      success: true,
      message: 'Pit updated successfully',
      data: pit
    });
  } catch (error) {
    console.error('Update Pit Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update pit',
      error: error.message
    });
  }
};

// Bulk update pits
export const bulkUpdatePits = async (req, res) => {
  try {
    const { updates } = req.body;

    if (!Array.isArray(updates) || updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Updates array is required and cannot be empty'
      });
    }

    const bulkOps = updates.map(update => ({
      updateOne: {
        filter: { _id: update.id, isLocked: false },
        update: {
          $set: {
            ...(update.pitName && { pitName: update.pitName }),
            ...(update.capacity !== undefined && { capacity: update.capacity }),
            ...(update.initialActive !== undefined && { initialActive: update.initialActive }),
            updatedAt: Date.now()
          }
        }
      }
    }));

    const result = await Pit.bulkWrite(bulkOps);

    res.status(200).json({
      success: true,
      message: 'Pits updated successfully',
      modifiedCount: result.modifiedCount
    });
  } catch (error) {
    console.error('Bulk Update Pits Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update pits',
      error: error.message
    });
  }
};

// Lock/Unlock pit
export const toggleLockPit = async (req, res) => {
  try {
    const { id } = req.params;
    const { isLocked } = req.body;

    const pit = await Pit.findById(id);

    if (!pit) {
      return res.status(404).json({
        success: false,
        message: 'Pit not found'
      });
    }

    pit.isLocked = isLocked !== undefined ? isLocked : !pit.isLocked;
    await pit.save();

    res.status(200).json({
      success: true,
      message: `Pit ${pit.isLocked ? 'locked' : 'unlocked'} successfully`,
      data: pit
    });
  } catch (error) {
    console.error('Toggle Lock Pit Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle pit lock',
      error: error.message
    });
  }
};

// ============= DELETE OPERATIONS =============

// Delete single pit
export const deletePit = async (req, res) => {
  try {
    const { id } = req.params;

    const pit = await Pit.findById(id);

    if (!pit) {
      return res.status(404).json({
        success: false,
        message: 'Pit not found'
      });
    }

    // Check if pit is locked
    if (pit.isLocked) {
      return res.status(403).json({
        success: false,
        message: 'Cannot delete locked pit'
      });
    }

    await Pit.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: 'Pit deleted successfully'
    });
  } catch (error) {
    console.error('Delete Pit Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete pit',
      error: error.message
    });
  }
};

// Bulk delete pits
export const bulkDeletePits = async (req, res) => {
  try {
    const { ids } = req.body;

    if (!Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'IDs array is required and cannot be empty'
      });
    }

    // Only delete unlocked pits
    const result = await Pit.deleteMany({ 
      _id: { $in: ids },
      isLocked: false 
    });

    res.status(200).json({
      success: true,
      message: `${result.deletedCount} pits deleted successfully`,
      deletedCount: result.deletedCount
    });
  } catch (error) {
    console.error('Bulk Delete Pits Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete pits',
      error: error.message
    });
  }
};

// Delete all pits for a well (admin only)
export const deleteAllPitsByWell = async (req, res) => {
  try {
    const { wellId } = req.params;

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: 'wellId is required'
      });
    }

    const result = await Pit.deleteMany({ wellId, isLocked: false });

    res.status(200).json({
      success: true,
      message: `${result.deletedCount} pits deleted successfully`,
      deletedCount: result.deletedCount
    });
  } catch (error) {
    console.error('Delete All Pits Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete pits',
      error: error.message
    });
  }
};
