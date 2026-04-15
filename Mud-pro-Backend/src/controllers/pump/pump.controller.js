import mongoose from "mongoose";
import Pump from "../../modules/pump/pump.model.js";
import {
  readReportId,
  readReportNo,
  readWellId,
  toText,
} from "../../utils/reportScope.js";

const normalizeObjectId = (value) => {
  const textValue = toText(value);
  return mongoose.Types.ObjectId.isValid(textValue) ? textValue : "";
};

const cleanClone = (doc = {}) => {
  const clone = { ...doc };
  delete clone._id;
  delete clone.id;
  delete clone.__v;
  delete clone.createdAt;
  delete clone.updatedAt;
  delete clone.reportId;
  delete clone.reportNo;
  return clone;
};

const sortByRowNumber = (items = []) =>
  [...items].sort((left, right) => {
    const leftRow = Number(left?.rowNumber) || 0;
    const rightRow = Number(right?.rowNumber) || 0;
    if (leftRow !== rightRow) return leftRow - rightRow;

    const leftTime = new Date(left?.createdAt ?? 0).getTime();
    const rightTime = new Date(right?.createdAt ?? 0).getTime();
    return leftTime - rightTime;
  });

const calculateDisplacement = (
  type,
  linerId,
  strokeLength,
  efficiency,
  rodOd = 0
) => {
  const D = Number(linerId) || 0;
  const L = Number(strokeLength) || 0;
  const eff = (Number(efficiency) || 0) / 100;
  const d = Number(rodOd) || 0;

  if (!D || !L || !eff) return 0;

  if (type === "Duplex") {
    if (d > 0) {
      return +(0.000162 * (2 * D * D - d * d) * L * eff).toFixed(4);
    }

    return +(0.000324 * D * D * L * eff).toFixed(4);
  }

  let constant = 0;
  if (type === "Triplex") constant = 0.000243;
  else if (type === "Quadplex") constant = 0.000324;
  else if (type === "Quintuplex") constant = 0.000405;

  if (!constant) return 0;
  return +(constant * D * D * L * eff).toFixed(4);
};

const calculateRate = (displacement, spm) => {
  const disp = Number(displacement) || 0;
  const SPM = Number(spm) || 0;

  if (!disp || !SPM) return 0;

  return +(disp * SPM * 42).toFixed(1);
};

const resolveScope = (req, existing = {}) => {
  const wellId = normalizeObjectId(readWellId(req) || existing.wellId);
  const reportId = normalizeObjectId(readReportId(req) || existing.reportId);
  const reportNo = reportId
    ? toText(readReportNo(req) || existing.reportNo)
    : "";

  return { wellId, reportId, reportNo };
};

const legacyPumpFilter = (wellId) => ({
  ...(wellId ? { wellId } : {}),
  $or: [{ reportId: { $exists: false } }, { reportId: null }],
});

const loadLegacyPumps = async (wellId) =>
  sortByRowNumber(
    await Pump.find(legacyPumpFilter(wellId))
      .sort({ rowNumber: 1, createdAt: 1, _id: 1 })
      .lean()
  );

const loadScopedPumps = async (wellId, reportId) => {
  if (!wellId || !reportId) {
    return [];
  }

  return sortByRowNumber(
    await Pump.find({ wellId, reportId })
      .sort({ rowNumber: 1, createdAt: 1, _id: 1 })
      .lean()
  );
};

const loadDisplayPumps = async ({ wellId, reportId }) => {
  if (wellId && reportId) {
    const scoped = await loadScopedPumps(wellId, reportId);
    if (scoped.length > 0) {
      return scoped;
    }
    return loadLegacyPumps(wellId);
  }

  if (wellId) {
    return loadLegacyPumps(wellId);
  }

  if (reportId) {
    return sortByRowNumber(
      await Pump.find({ reportId })
        .sort({ rowNumber: 1, createdAt: 1, _id: 1 })
        .lean()
    );
  }

  return sortByRowNumber(
    await Pump.find({})
      .sort({ rowNumber: 1, createdAt: 1, _id: 1 })
      .lean()
  );
};

const ensureReportPumpSet = async ({ wellId, reportId, reportNo }) => {
  if (!wellId || !reportId) {
    return [];
  }

  const scoped = await loadScopedPumps(wellId, reportId);
  if (scoped.length > 0) {
    return scoped;
  }

  const legacy = await loadLegacyPumps(wellId);
  if (legacy.length === 0) {
    return [];
  }

  await Pump.insertMany(
    legacy.map((item) => ({
      ...cleanClone(item),
      wellId,
      reportId,
      reportNo,
    }))
  );

  return loadScopedPumps(wellId, reportId);
};

const nextRowNumberForScope = async ({ wellId, reportId }) => {
  const filter =
    wellId && reportId
      ? { wellId, reportId }
      : wellId
      ? legacyPumpFilter(wellId)
      : {};

  const lastPump = await Pump.findOne(filter)
    .sort({ rowNumber: -1, createdAt: -1 })
    .select("rowNumber")
    .lean();

  return Number(lastPump?.rowNumber || 0) + 1;
};

const buildPumpPayload = ({
  body = {},
  existing = {},
  wellId,
  reportId,
  reportNo,
  rowNumber,
}) => {
  const type = body.type ?? existing.type;
  const linerId = body.linerId ?? existing.linerId;
  const strokeLength = body.strokeLength ?? existing.strokeLength;
  const efficiency = body.efficiency ?? existing.efficiency;
  const spm = body.spm ?? existing.spm;
  const rodOd = body.rodOd ?? existing.rodOd;
  const displacement = calculateDisplacement(
    type,
    linerId,
    strokeLength,
    efficiency,
    rodOd
  );
  const rate = calculateRate(displacement, spm);

  return {
    ...cleanClone(existing),
    ...body,
    rowNumber: Number(rowNumber) || 1,
    displacement,
    rate,
    wellId: wellId || null,
    reportId: reportId || null,
    reportNo: reportId ? reportNo : "",
  };
};

class PumpController {
  async getPumps(req, res) {
    try {
      const { wellId, reportId } = resolveScope(req);

      if (req.query.wellId && !wellId) {
        return res.status(400).json({
          success: false,
          message: "Invalid well ID",
        });
      }

      const pumps = await loadDisplayPumps({ wellId, reportId });

      return res.status(200).json({
        success: true,
        message: "Pumps retrieved successfully",
        data: pumps,
      });
    } catch (error) {
      console.error(error);
      return res.status(500).json({
        success: false,
        message: "Failed to fetch pumps",
        error: error.message,
      });
    }
  }

  async getPumpById(req, res) {
    try {
      const { id } = req.params;

      if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({
          success: false,
          message: "Invalid pump ID",
        });
      }

      const pump = await Pump.findById(id).lean();

      if (!pump) {
        return res.status(404).json({
          success: false,
          message: "Pump not found",
        });
      }

      return res.status(200).json({
        success: true,
        data: pump,
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }

  async createPump(req, res) {
    try {
      const scope = resolveScope(req);

      if (req.body.wellId && !scope.wellId) {
        return res.status(400).json({
          success: false,
          message: "Invalid well ID",
        });
      }

      if (scope.reportId) {
        await ensureReportPumpSet(scope);
      }

      const requestedRowNumber = Number(req.body.rowNumber) || 0;
      const rowNumber =
        requestedRowNumber || (await nextRowNumberForScope(scope));

      const existingScoped =
        scope.wellId && scope.reportId
          ? await Pump.findOne({
              wellId: scope.wellId,
              reportId: scope.reportId,
              rowNumber,
            })
          : null;

      const pumpData = buildPumpPayload({
        body: req.body,
        wellId: scope.wellId,
        reportId: scope.reportId,
        reportNo: scope.reportNo,
        rowNumber,
      });

      if (existingScoped) {
        const updated = await Pump.findByIdAndUpdate(
          existingScoped._id,
          pumpData,
          { new: true, runValidators: true }
        );

        return res.status(200).json({
          success: true,
          message: "Pump updated successfully",
          data: updated,
        });
      }

      const pump = await Pump.create(pumpData);

      return res.status(201).json({
        success: true,
        message: "Pump created successfully",
        data: pump,
      });
    } catch (error) {
      console.error(error);
      return res.status(500).json({
        success: false,
        message: "Failed to create pump",
        error: error.message,
      });
    }
  }

  async updatePump(req, res) {
    try {
      const { id } = req.params;
      const existing = await Pump.findById(id);

      if (!existing) {
        return res.status(404).json({
          success: false,
          message: "Pump not found",
        });
      }

      const scope = resolveScope(req, existing);
      const rowNumber = Number(req.body.rowNumber ?? existing.rowNumber) || 1;

      if (scope.reportId && toText(existing.reportId) !== scope.reportId) {
        const scopedRows = await ensureReportPumpSet(scope);
        const scopedMatch = scopedRows.find(
          (item) => Number(item.rowNumber) === rowNumber
        );

        const pumpData = buildPumpPayload({
          body: req.body,
          existing: scopedMatch ?? existing.toObject(),
          wellId: scope.wellId,
          reportId: scope.reportId,
          reportNo: scope.reportNo,
          rowNumber,
        });

        const scopedPump = scopedMatch
          ? await Pump.findByIdAndUpdate(scopedMatch._id, pumpData, {
              new: true,
              runValidators: true,
            })
          : await Pump.create(pumpData);

        return res.status(200).json({
          success: true,
          message: "Pump updated successfully",
          data: scopedPump,
        });
      }

      const pumpData = buildPumpPayload({
        body: req.body,
        existing: existing.toObject(),
        wellId: scope.wellId,
        reportId: scope.reportId,
        reportNo: scope.reportNo,
        rowNumber,
      });

      const pump = await Pump.findByIdAndUpdate(id, pumpData, {
        new: true,
        runValidators: true,
      });

      return res.status(200).json({
        success: true,
        message: "Pump updated successfully",
        data: pump,
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        message: "Failed to update pump",
        error: error.message,
      });
    }
  }

  async deletePump(req, res) {
    try {
      const { id } = req.params;
      const existing = await Pump.findById(id);

      if (!existing) {
        return res.status(404).json({
          success: false,
          message: "Pump not found",
        });
      }

      const scope = resolveScope(req, existing);

      if (scope.reportId && toText(existing.reportId) !== scope.reportId) {
        const scopedRows = await ensureReportPumpSet(scope);
        const scopedMatch = scopedRows.find(
          (item) => Number(item.rowNumber) === Number(existing.rowNumber)
        );

        if (scopedMatch?._id) {
          await Pump.findByIdAndDelete(scopedMatch._id);
        }

        return res.status(200).json({
          success: true,
          message: "Pump deleted successfully",
        });
      }

      await Pump.findByIdAndDelete(id);

      return res.status(200).json({
        success: true,
        message: "Pump deleted successfully",
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }

  async deleteAllPumps(req, res) {
    try {
      const { wellId, reportId } = resolveScope(req);
      const filter =
        wellId && reportId
          ? { wellId, reportId }
          : wellId
          ? legacyPumpFilter(wellId)
          : {};

      await Pump.deleteMany(filter);

      return res.status(200).json({
        success: true,
        message: "All pumps deleted successfully",
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }

  async bulkUpsertPumps(req, res) {
    try {
      const { pumps } = req.body;
      if (!Array.isArray(pumps)) {
        return res.status(400).json({
          success: false,
          message: "Pumps must be an array",
        });
      }

      const scope = resolveScope(req);
      if (scope.reportId && scope.wellId) {
        await ensureReportPumpSet(scope);
      }

      const operations = pumps.map((pump, index) => {
        const itemWellId = normalizeObjectId(pump.wellId || scope.wellId);
        const itemReportId = normalizeObjectId(pump.reportId || scope.reportId);
        const itemReportNo = itemReportId
          ? toText(pump.reportNo || scope.reportNo)
          : "";
        const rowNumber = Number(pump.rowNumber) || index + 1;

        const pumpData = buildPumpPayload({
          body: pump,
          wellId: itemWellId,
          reportId: itemReportId,
          reportNo: itemReportNo,
          rowNumber,
        });

        if (itemWellId && itemReportId) {
          return {
            updateOne: {
              filter: { wellId: itemWellId, reportId: itemReportId, rowNumber },
              update: { $set: pumpData },
              upsert: true,
            },
          };
        }

        if (pump._id && mongoose.Types.ObjectId.isValid(pump._id)) {
          return {
            updateOne: {
              filter: { _id: pump._id },
              update: { $set: pumpData },
              upsert: false,
            },
          };
        }

        return {
          insertOne: {
            document: pumpData,
          },
        };
      });

      const result = await Pump.bulkWrite(operations);

      return res.status(200).json({
        success: true,
        message: "Bulk operation successful",
        data: result,
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }

  async calculateDisplacementEndpoint(req, res) {
    try {
      const { type, linerId, strokeLength, efficiency, rodOd } = req.body;
      const displacement = calculateDisplacement(
        type,
        linerId,
        strokeLength,
        efficiency,
        rodOd
      );

      return res.status(200).json({
        success: true,
        displacement,
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }
}

export default new PumpController();
