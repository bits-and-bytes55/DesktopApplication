import mongoose from 'mongoose';
import Pump from '../../modules/pump/pump.model.js';

const calculateDisplacement = (type, linerId, strokeLength) => {
  const D = Number(linerId) || 0;
  const L = Number(strokeLength) || 0;

  let N = 0;

  if (type === "Triplex") N = 3;
  if (type === "Duplex") N = 2;
  if (type === "Quintuplex") N = 5;

  if (!D || !L || !N) return 0;

  const displacement = (0.000971 * Math.pow(D, 2) * L * N) / 42;

  return +displacement.toFixed(3);
};
class PumpController {
  // Get all pumps for a well
  async getPumps(req, res) {
    try {
      const { wellId } = req.params;

      if (!wellId || !mongoose.Types.ObjectId.isValid(wellId)) {
        return res.status(400).json({
          success: false,
          message: 'Valid well ID is required'
        });
      }

      const pumps = await Pump.find({ wellId })
        .sort({ rowNumber: 1 })
        .lean();

      return res.status(200).json({
        success: true,
        message: 'Pumps retrieved successfully',
        data: pumps
      });
    } catch (error) {
      console.error('Error fetching pumps:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch pumps',
        error: error.message
      });
    }
  }

  // Get single pump by ID
  async getPumpById(req, res) {
    try {
      const { id } = req.params;

      if (!id || !mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({
          success: false,
          message: 'Valid pump ID is required'
        });
      }

      const pump = await Pump.findById(id).lean();

      if (!pump) {
        return res.status(404).json({
          success: false,
          message: 'Pump not found'
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Pump retrieved successfully',
        data: pump
      });
    } catch (error) {
      console.error('Error fetching pump:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch pump',
        error: error.message
      });
    }
  }

  // Create new pump
  async createPump(req, res) {
    try {
      const { wellId } = req.params;
      const userId = req.user?.id || req.user?._id;

      if (!wellId || !mongoose.Types.ObjectId.isValid(wellId)) {
        return res.status(400).json({
          success: false,
          message: 'Valid well ID is required'
        });
      }

      // Get the highest row number for this well
      const lastPump = await Pump.findOne({ wellId })
        .sort({ rowNumber: -1 })
        .select('rowNumber')
        .lean();

      const rowNumber = req.body.rowNumber || (lastPump ? lastPump.rowNumber + 1 : 1);
      const displacement = calculateDisplacement(
  req.body.type,
  req.body.linerId,
  req.body.strokeLength
);

      const pumpData = {
  ...req.body,
  displacement,
  wellId,
  rowNumber,
  createdBy: userId,
  updatedBy: userId
};

      const pump = await Pump.create(pumpData);

      return res.status(201).json({
        success: true,
        message: 'Pump created successfully',
        data: pump
      });
    } catch (error) {
      console.error('Error creating pump:', error);
      
      // Handle duplicate row number error
      if (error.code === 11000) {
        return res.status(409).json({
          success: false,
          message: 'A pump with this row number already exists for this well'
        });
      }

      return res.status(500).json({
        success: false,
        message: 'Failed to create pump',
        error: error.message
      });
    }
  }

  // Update pump
  async updatePump(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user?.id || req.user?._id;

      if (!id || !mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({
          success: false,
          message: 'Valid pump ID is required'
        });
      }
      const displacement = calculateDisplacement(
  req.body.type || existing.type,
  req.body.linerId || existing.linerId,
  req.body.strokeLength || existing.strokeLength
);

      const updateData = {
  ...req.body,
  displacement,
  updatedBy: userId,
  updatedAt: Date.now()
};

      // Remove fields that shouldn't be updated
      delete updateData._id;
      delete updateData.wellId;
      delete updateData.rowNumber;
      delete updateData.createdBy;
      delete updateData.createdAt;

      const pump = await Pump.findByIdAndUpdate(
        id,
        updateData,
        { new: true, runValidators: true }
      );

      if (!pump) {
        return res.status(404).json({
          success: false,
          message: 'Pump not found'
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Pump updated successfully',
        data: pump
      });
    } catch (error) {
      console.error('Error updating pump:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to update pump',
        error: error.message
      });
    }
  }

  // Delete pump
  async deletePump(req, res) {
    try {
      const { id } = req.params;

      if (!id || !mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({
          success: false,
          message: 'Valid pump ID is required'
        });
      }

      const pump = await Pump.findByIdAndDelete(id);

      if (!pump) {
        return res.status(404).json({
          success: false,
          message: 'Pump not found'
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Pump deleted successfully',
        data: pump
      });
    } catch (error) {
      console.error('Error deleting pump:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to delete pump',
        error: error.message
      });
    }
  }

  // Delete all pumps for a well
  async deleteAllPumps(req, res) {
    try {
      const { wellId } = req.params;

      if (!wellId || !mongoose.Types.ObjectId.isValid(wellId)) {
        return res.status(400).json({
          success: false,
          message: 'Valid well ID is required'
        });
      }

      const result = await Pump.deleteMany({ wellId });

      return res.status(200).json({
        success: true,
        message: `${result.deletedCount} pumps deleted successfully`,
        data: { deletedCount: result.deletedCount }
      });
    } catch (error) {
      console.error('Error deleting pumps:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to delete pumps',
        error: error.message
      });
    }
  }

  // Bulk create/update pumps
  async bulkUpsertPumps(req, res) {
    try {
      const { wellId } = req.params;
      const { pumps } = req.body;
      const userId = req.user?.id || req.user?._id;

      if (!wellId || !mongoose.Types.ObjectId.isValid(wellId)) {
        return res.status(400).json({
          success: false,
          message: 'Valid well ID is required'
        });
      }

      if (!Array.isArray(pumps)) {
        return res.status(400).json({
          success: false,
          message: 'Pumps must be an array'
        });
      }

      const operations = pumps.map((pump, index) => {
        if (pump._id) {
          // Update existing pump
          return {
            updateOne: {
              filter: { _id: pump._id, wellId },
              update: { 
                $set: {
                  ...pump, 
                  updatedBy: userId,
                  updatedAt: Date.now()
                }
              },
              upsert: false
            }
          };
        } else {
          // Insert new pump
          return {
            insertOne: {
              document: {
                ...pump,
                wellId,
                rowNumber: pump.rowNumber || index + 1,
                createdBy: userId,
                updatedBy: userId
              }
            }
          };
        }
      });

      const result = await Pump.bulkWrite(operations);

      return res.status(200).json({
        success: true,
        message: 'Pumps updated successfully',
        data: result
      });
    } catch (error) {
      console.error('Error bulk upserting pumps:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to update pumps',
        error: error.message
      });
    }
  }
}

export default new PumpController();