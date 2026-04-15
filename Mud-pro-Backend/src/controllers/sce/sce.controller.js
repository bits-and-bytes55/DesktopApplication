import { Shaker, OtherSce } from '../../modules/sce/sce.model.js';
import mongoose from 'mongoose';
import {
  readReportId,
  readReportNo,
  toText,
} from '../../utils/reportScope.js';

const normalizeObjectId = (value) => {
  const textValue = toText(value);
  return mongoose.Types.ObjectId.isValid(textValue) ? textValue : '';
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

const sortByCreatedAtAsc = (items = []) =>
  [...items].sort((left, right) => {
    const leftTime = new Date(left?.createdAt ?? 0).getTime();
    const rightTime = new Date(right?.createdAt ?? 0).getTime();
    return leftTime - rightTime;
  });

const resolveScope = (req, existing = {}) => {
  const wellId = normalizeObjectId(
    req.params?.wellId ?? req.body?.wellId ?? existing.wellId
  );
  const reportId = normalizeObjectId(readReportId(req) || existing.reportId);
  const reportNo = reportId
    ? toText(readReportNo(req) || existing.reportNo)
    : '';

  return { wellId, reportId, reportNo };
};

const legacyScopeFilter = (wellId, extra = {}) => ({
  ...(wellId ? { wellId } : {}),
  ...extra,
  $or: [{ reportId: { $exists: false } }, { reportId: null }],
});

const loadLegacyRows = async (Model, wellId) =>
  sortByCreatedAtAsc(
    await Model.find(legacyScopeFilter(wellId))
      .sort({ createdAt: 1, _id: 1 })
      .lean()
  );

const loadScopedRows = async (Model, wellId, reportId) => {
  if (!wellId || !reportId) {
    return [];
  }

  return sortByCreatedAtAsc(
    await Model.find({ wellId, reportId })
      .sort({ createdAt: 1, _id: 1 })
      .lean()
  );
};

const loadDisplayRows = async (Model, { wellId, reportId }) => {
  if (wellId && reportId) {
    const scoped = await loadScopedRows(Model, wellId, reportId);
    if (scoped.length > 0) {
      return scoped;
    }
    return loadLegacyRows(Model, wellId);
  }

  if (wellId) {
    return loadLegacyRows(Model, wellId);
  }

  if (reportId) {
    return sortByCreatedAtAsc(
      await Model.find({ reportId })
        .sort({ createdAt: 1, _id: 1 })
        .lean()
    );
  }

  return sortByCreatedAtAsc(
    await Model.find({})
      .sort({ createdAt: 1, _id: 1 })
      .lean()
  );
};

const ensureReportSet = async ({
  Model,
  wellId,
  reportId,
  reportNo,
}) => {
  if (!wellId || !reportId) {
    return [];
  }

  const scoped = await loadScopedRows(Model, wellId, reportId);
  if (scoped.length > 0) {
    return scoped;
  }

  const legacy = await loadLegacyRows(Model, wellId);
  if (legacy.length === 0) {
    return [];
  }

  await Model.insertMany(
    legacy.map((item) => ({
      ...cleanClone(item),
      wellId,
      reportId,
      reportNo,
    }))
  );

  return loadScopedRows(Model, wellId, reportId);
};

const buildShakerPayload = ({
  body = {},
  existing = {},
  wellId,
  reportId,
  reportNo,
}) => ({
  ...cleanClone(existing),
  wellId: wellId || null,
  reportId: reportId || null,
  reportNo: reportId ? reportNo : '',
  shaker: toText(body.shaker ?? existing.shaker),
  model: toText(body.model ?? existing.model),
  screens: toText(body.screens ?? existing.screens),
  plot:
    typeof body.plot === 'boolean'
      ? body.plot
      : Boolean(existing.plot ?? false),
  screen1: toText(body.screen1 ?? existing.screen1),
  screen2: toText(body.screen2 ?? existing.screen2),
  screen3: toText(body.screen3 ?? existing.screen3),
  screen4: toText(body.screen4 ?? existing.screen4),
  screen5: toText(body.screen5 ?? existing.screen5),
  screen6: toText(body.screen6 ?? existing.screen6),
  screen7: toText(body.screen7 ?? existing.screen7),
  screen8: toText(body.screen8 ?? existing.screen8),
  time: toText(body.time ?? existing.time),
  oocWt: toText(body.oocWt ?? existing.oocWt),
});

const buildOtherScePayload = ({
  body = {},
  existing = {},
  wellId,
  reportId,
  reportNo,
}) => ({
  ...cleanClone(existing),
  wellId: wellId || null,
  reportId: reportId || null,
  reportNo: reportId ? reportNo : '',
  type: toText(body.type ?? existing.type),
  model1: toText(body.model1 ?? existing.model1),
  model2: toText(body.model2 ?? existing.model2),
  model3: toText(body.model3 ?? existing.model3),
  plot:
    typeof body.plot === 'boolean'
      ? body.plot
      : Boolean(existing.plot ?? false),
  uf: toText(body.uf ?? existing.uf),
  of: toText(body.of ?? existing.of),
  time: toText(body.time ?? existing.time),
  oocWt: toText(body.oocWt ?? existing.oocWt),
});

// ==================== SHAKER CONTROLLERS ====================

// Get all shakers for a well
export const getShakers = async (req, res) => {
  try {
    const { wellId, reportId } = resolveScope(req);
    
    if (req.params?.wellId && !wellId) {
      return res.status(400).json({
        success: false,
        message: 'Invalid well ID'
      });
    }

    const shakers = await loadDisplayRows(Shaker, { wellId, reportId });
    
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
    const scope = resolveScope(req);
    const payload = buildShakerPayload({
      body: req.body,
      wellId: scope.wellId,
      reportId: scope.reportId,
      reportNo: scope.reportNo,
    });

    if (req.params?.wellId && !scope.wellId) {
      return res.status(400).json({
        success: false,
        message: 'Invalid well ID'
      });
    }

    if (!payload.shaker) {
      return res.status(400).json({
        success: false,
        message: 'Shaker name is required'
      });
    }

    if (scope.reportId) {
      await ensureReportSet({
        Model: Shaker,
        wellId: scope.wellId,
        reportId: scope.reportId,
        reportNo: scope.reportNo,
      });
    }

    const existing = scope.reportId
      ? await Shaker.findOne({
          wellId: scope.wellId,
          reportId: scope.reportId,
          shaker: payload.shaker,
        })
      : await Shaker.findOne(
          legacyScopeFilter(scope.wellId, { shaker: payload.shaker })
        );

    const newShaker = existing
      ? await Shaker.findByIdAndUpdate(existing._id, payload, {
          new: true,
          runValidators: true,
        })
      : await Shaker.create(payload);

    res.status(existing ? 200 : 201).json({
      success: true,
      message: existing
        ? 'Shaker updated successfully'
        : 'Shaker created successfully',
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

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid shaker ID'
      });
    }

    const existing = await Shaker.findById(id);
    if (!existing) {
      return res.status(404).json({
        success: false,
        message: 'Shaker not found'
      });
    }

    const scope = resolveScope(req, existing);
    const targetKey = toText(req.body.shaker || existing.shaker);
    const payload = buildShakerPayload({
      body: req.body,
      existing: existing.toObject(),
      wellId: scope.wellId,
      reportId: scope.reportId,
      reportNo: scope.reportNo,
    });

    let updatedShaker;
    if (scope.reportId && toText(existing.reportId) !== scope.reportId) {
      await ensureReportSet({
        Model: Shaker,
        wellId: scope.wellId,
        reportId: scope.reportId,
        reportNo: scope.reportNo,
      });

      const scopedMatch = await Shaker.findOne({
        wellId: scope.wellId,
        reportId: scope.reportId,
        shaker: targetKey,
      });

      updatedShaker = scopedMatch
        ? await Shaker.findByIdAndUpdate(scopedMatch._id, payload, {
            new: true,
            runValidators: true,
          })
        : await Shaker.create(payload);
    } else {
      updatedShaker = await Shaker.findByIdAndUpdate(id, payload, {
        new: true,
        runValidators: true,
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

    const existing = await Shaker.findById(id);
    if (!existing) {
      return res.status(404).json({
        success: false,
        message: 'Shaker not found'
      });
    }

    const scope = resolveScope(req, existing);
    let deletedShaker = existing;

    if (scope.reportId && toText(existing.reportId) !== scope.reportId) {
      await ensureReportSet({
        Model: Shaker,
        wellId: scope.wellId,
        reportId: scope.reportId,
        reportNo: scope.reportNo,
      });

      const scopedMatch = await Shaker.findOne({
        wellId: scope.wellId,
        reportId: scope.reportId,
        shaker: toText(existing.shaker),
      });

      if (scopedMatch) {
        deletedShaker = await Shaker.findByIdAndDelete(scopedMatch._id);
      }
    } else {
      deletedShaker = await Shaker.findByIdAndDelete(id);
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
    const { wellId, reportId } = resolveScope(req);
    
    if (req.params?.wellId && !wellId) {
      return res.status(400).json({
        success: false,
        message: 'Invalid well ID'
      });
    }

    const otherSce = await loadDisplayRows(OtherSce, { wellId, reportId });
    
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
    const scope = resolveScope(req);
    const payload = buildOtherScePayload({
      body: req.body,
      wellId: scope.wellId,
      reportId: scope.reportId,
      reportNo: scope.reportNo,
    });

    if (req.params?.wellId && !scope.wellId) {
      return res.status(400).json({
        success: false,
        message: 'Invalid well ID'
      });
    }

    if (!payload.type) {
      return res.status(400).json({
        success: false,
        message: 'Type is required'
      });
    }

    if (scope.reportId) {
      await ensureReportSet({
        Model: OtherSce,
        wellId: scope.wellId,
        reportId: scope.reportId,
        reportNo: scope.reportNo,
      });
    }

    const existing = scope.reportId
      ? await OtherSce.findOne({
          wellId: scope.wellId,
          reportId: scope.reportId,
          type: payload.type,
        })
      : await OtherSce.findOne(
          legacyScopeFilter(scope.wellId, { type: payload.type })
        );

    const newOtherSce = existing
      ? await OtherSce.findByIdAndUpdate(existing._id, payload, {
          new: true,
          runValidators: true,
        })
      : await OtherSce.create(payload);

    res.status(existing ? 200 : 201).json({
      success: true,
      message: existing
        ? 'Other SCE updated successfully'
        : 'Other SCE created successfully',
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

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid other SCE ID'
      });
    }

    const existing = await OtherSce.findById(id);
    if (!existing) {
      return res.status(404).json({
        success: false,
        message: 'Other SCE not found'
      });
    }

    const scope = resolveScope(req, existing);
    const targetKey = toText(req.body.type || existing.type);
    const payload = buildOtherScePayload({
      body: req.body,
      existing: existing.toObject(),
      wellId: scope.wellId,
      reportId: scope.reportId,
      reportNo: scope.reportNo,
    });

    let updatedOtherSce;
    if (scope.reportId && toText(existing.reportId) !== scope.reportId) {
      await ensureReportSet({
        Model: OtherSce,
        wellId: scope.wellId,
        reportId: scope.reportId,
        reportNo: scope.reportNo,
      });

      const scopedMatch = await OtherSce.findOne({
        wellId: scope.wellId,
        reportId: scope.reportId,
        type: targetKey,
      });

      updatedOtherSce = scopedMatch
        ? await OtherSce.findByIdAndUpdate(scopedMatch._id, payload, {
            new: true,
            runValidators: true,
          })
        : await OtherSce.create(payload);
    } else {
      updatedOtherSce = await OtherSce.findByIdAndUpdate(id, payload, {
        new: true,
        runValidators: true,
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

    const existing = await OtherSce.findById(id);
    if (!existing) {
      return res.status(404).json({
        success: false,
        message: 'Other SCE not found'
      });
    }

    const scope = resolveScope(req, existing);
    let deletedOtherSce = existing;

    if (scope.reportId && toText(existing.reportId) !== scope.reportId) {
      await ensureReportSet({
        Model: OtherSce,
        wellId: scope.wellId,
        reportId: scope.reportId,
        reportNo: scope.reportNo,
      });

      const scopedMatch = await OtherSce.findOne({
        wellId: scope.wellId,
        reportId: scope.reportId,
        type: toText(existing.type),
      });

      if (scopedMatch) {
        deletedOtherSce = await OtherSce.findByIdAndDelete(scopedMatch._id);
      }
    } else {
      deletedOtherSce = await OtherSce.findByIdAndDelete(id);
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
