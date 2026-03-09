import mongoose from 'mongoose';
import Pump from '../../modules/pump/pump.model.js';

// Formula: Displacement (bbl/stk) = (0.000971 × D² × L × N) / 42
// D = Liner ID (inches), L = Stroke Length (inches), N = number of cylinders
const calculateDisplacement = (type, linerId, strokeLength, efficiency) => {

  const D = Number(linerId) || 0;
  const L = Number(strokeLength) || 0;
  const eff = (Number(efficiency) || 0) / 100;

  let constant = 0;

 if (type === "Duplex") constant = 0.000324;            // ✅ double-acting
else if (type === "Triplex") constant = 0.000243;
else if (type === "Quadplex") constant = 0.000324;     // ✅ spelling fixed
else if (type === "Quintuplex") constant = 0.000405;

  if (!D || !L || !eff || !constant) return 0;

  const displacement = constant * Math.pow(D, 2) * L * eff;

  return +displacement.toFixed(4);
};

// Rate (GPM) = Displacement (bbl/stk) × SPM × Efficiency × 42
const calculateRate = (displacement, spm) => {

  const disp = Number(displacement) || 0;
  const SPM = Number(spm) || 0;

  if (!disp || !SPM) return 0;

  const rate = disp * SPM * 42;

  return +rate.toFixed(1);
};

class PumpController {

  // GET ALL PUMPS
  async getPumps(req, res) {
    try {
      const pumps = await Pump.find()
        .sort({ rowNumber: 1 })
        .lean();

      return res.status(200).json({
        success: true,
        message: 'Pumps retrieved successfully',
        data: pumps
      });

    } catch (error) {
      console.error(error);
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch pumps',
        error: error.message
      });
    }
  }

  // GET BY ID
  async getPumpById(req, res) {
    try {
      const { id } = req.params;

      if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid pump ID'
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
        data: pump
      });

    } catch (error) {
      return res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // CREATE
  async createPump(req, res) {
    try {
      const lastPump = await Pump.findOne()
        .sort({ rowNumber: -1 })
        .select('rowNumber')
        .lean();

      const rowNumber =
        req.body.rowNumber || (lastPump ? lastPump.rowNumber + 1 : 1);

      const displacement = calculateDisplacement(
        req.body.type,
        req.body.linerId,
        req.body.strokeLength,
        req.body.efficiency
      );

      const rate = calculateRate(
        displacement,
        req.body.spm,
        req.body.efficiency
      );

      // Build pump data without wellId if not provided
      const pumpData = {
        ...req.body,
        rowNumber,
        displacement,
        rate
      };

      // Only include wellId if it's valid
      if (req.body.wellId && mongoose.Types.ObjectId.isValid(req.body.wellId)) {
        pumpData.wellId = req.body.wellId;
      } else {
        delete pumpData.wellId;
      }

      const pump = await Pump.create(pumpData);

      return res.status(201).json({
        success: true,
        message: 'Pump created successfully',
        data: pump
      });

    } catch (error) {
      console.error(error);
      return res.status(500).json({
        success: false,
        message: 'Failed to create pump',
        error: error.message
      });
    }
  }

  // UPDATE
  async updatePump(req, res) {
    try {
      const { id } = req.params;

      const existing = await Pump.findById(id);

      if (!existing) {
        return res.status(404).json({
          success: false,
          message: 'Pump not found'
        });
      }

      const type = req.body.type ?? existing.type;
      const linerId = req.body.linerId ?? existing.linerId;
      const strokeLength = req.body.strokeLength ?? existing.strokeLength;
      const spm = req.body.spm ?? existing.spm;
      const efficiency = req.body.efficiency ?? existing.efficiency;

     
      const displacement = calculateDisplacement(type, linerId, strokeLength, efficiency); // ✅

      const rate = calculateRate(displacement, spm, efficiency);

      const updateData = {
        ...req.body,
        displacement,
        rate,
        updatedAt: Date.now()
      };

      // Don't overwrite wellId with invalid value
      if (req.body.wellId && !mongoose.Types.ObjectId.isValid(req.body.wellId)) {
        delete updateData.wellId;
      }

      const pump = await Pump.findByIdAndUpdate(
        id,
        updateData,
        { new: true, runValidators: true }
      );

      return res.status(200).json({
        success: true,
        message: 'Pump updated successfully',
        data: pump
      });

    } catch (error) {
      return res.status(500).json({
        success: false,
        message: 'Failed to update pump',
        error: error.message
      });
    }
  }

  // DELETE ONE
  async deletePump(req, res) {
    try {
      const { id } = req.params;

      const pump = await Pump.findByIdAndDelete(id);

      if (!pump) {
        return res.status(404).json({
          success: false,
          message: 'Pump not found'
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Pump deleted successfully'
      });

    } catch (error) {
      return res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // DELETE ALL
  async deleteAllPumps(req, res) {
    try {
      await Pump.deleteMany({});

      return res.status(200).json({
        success: true,
        message: 'All pumps deleted successfully'
      });

    } catch (error) {
      return res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // BULK UPSERT
  async bulkUpsertPumps(req, res) {
    try {
      const { pumps } = req.body;

      if (!Array.isArray(pumps)) {
        return res.status(400).json({
          success: false,
          message: 'Pumps must be an array'
        });
      }

      const operations = pumps.map((pump, index) => {
        // Calculate displacement and rate for each pump
        const displacement = calculateDisplacement(pump.type, pump.linerId, pump.strokeLength);
        const rate = calculateRate(displacement, pump.spm, pump.efficiency);

        const pumpData = {
          ...pump,
          displacement,
          rate,
          rowNumber: pump.rowNumber || index + 1
        };

        // Remove invalid wellId
        if (pumpData.wellId && !mongoose.Types.ObjectId.isValid(pumpData.wellId)) {
          delete pumpData.wellId;
        }

        if (pump._id) {
          return {
            updateOne: {
              filter: { _id: pump._id },
              update: { $set: pumpData },
              upsert: false
            }
          };
        } else {
          return {
            insertOne: {
              document: pumpData
            }
          };
        }
      });

      const result = await Pump.bulkWrite(operations);

      return res.status(200).json({
        success: true,
        message: 'Bulk operation successful',
        data: result
      });

    } catch (error) {
      return res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // CALCULATE DISPLACEMENT (utility endpoint for frontend)
  async calculateDisplacementEndpoint(req, res) {
    try {
      const { type, linerId, strokeLength } = req.body;
      const displacement = calculateDisplacement(type, linerId, strokeLength);

      return res.status(200).json({
        success: true,
        displacement
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }
}

export default new PumpController();