import mongoose from "mongoose";
import DrillString from "../../modules/DrillString/DrillString.js";
import {
  legacyReportScope,
  readReportId,
  readReportNo,
  readWellId,
  toText,
} from "../../utils/reportScope.js";

const normalizeObjectId = (value) => {
  const textValue = toText(value);
  return mongoose.Types.ObjectId.isValid(textValue) ? textValue : "";
};

const resolveScope = (req, existing = {}) => {
  const wellId = normalizeObjectId(readWellId(req) || existing.wellId);
  const reportId = normalizeObjectId(readReportId(req) || existing.reportId);
  const reportNo = reportId
    ? toText(readReportNo(req) || existing.reportNo)
    : "";

  return { wellId, reportId, reportNo };
};

const toSortOrder = (value) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};

const emptyFieldFilter = (field) => ({
  $or: [{ [field]: { $exists: false } }, { [field]: null }, { [field]: "" }],
});

const legacyWellFilter = (wellId) => ({
  wellId,
  ...legacyReportScope(),
});

const legacyGlobalFilter = () => ({
  $and: [emptyFieldFilter("wellId"), legacyReportScope()],
});

const loadScopedDrillStrings = async (wellId, reportId) => {
  if (!wellId || !reportId) {
    return [];
  }

  return DrillString.find({ wellId, reportId })
    .sort({ sortOrder: 1, createdAt: 1, _id: 1 })
    .lean();
};

const loadLegacyDrillStrings = async (wellId) => {
  if (wellId) {
    const wellScoped = await DrillString.find(legacyWellFilter(wellId))
      .sort({ sortOrder: 1, createdAt: 1, _id: 1 })
      .lean();

    if (wellScoped.length > 0) {
      return wellScoped;
    }
  }

  return DrillString.find(legacyGlobalFilter())
    .sort({ sortOrder: 1, createdAt: 1, _id: 1 })
    .lean();
};

const loadDisplayDrillStrings = async ({ wellId, reportId }) => {
  if (wellId && reportId) {
    return loadScopedDrillStrings(wellId, reportId);
  }

  if (wellId) {
    return loadLegacyDrillStrings(wellId);
  }

  if (reportId) {
    return DrillString.find({ reportId })
      .sort({ sortOrder: 1, createdAt: 1, _id: 1 })
      .lean();
  }

  return DrillString.find({})
    .sort({ sortOrder: 1, createdAt: 1, _id: 1 })
    .lean();
};

/**
 * @desc Create Drill String Entry
 */
export const createDrillString = async (req, res) => {
  try {
    const { wellId, reportId, reportNo } = resolveScope(req);
    const { description, od, weightPpf, id, grade, length, sortOrder } =
      req.body;

    const drill = await DrillString.create({
      wellId: wellId || null,
      reportId: reportId || null,
      reportNo: reportId ? reportNo : "",
      description,
      od: Number(od || 0),
      weightPpf: Number(weightPpf || 0),
      id: Number(id || 0),
      grade,
      length: Number(length || 0),
      sortOrder: toSortOrder(sortOrder),
    });

    res.status(201).json({
      success: true,
      message: "Drill String Added Successfully",
      data: drill
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};


/**
 * @desc Get All Drill Strings + Total Length Calculation
 */
export const getDrillStrings = async (req, res) => {
  try {
    const scope = resolveScope(req);
    const data = await loadDisplayDrillStrings(scope);

    const totalLength = data.reduce(
      (sum, item) => sum + Number(item.length || 0),
      0
    );

    res.status(200).json({
      success: true,
      count: data.length,
      totalLength,
      data
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};


/**
 * @desc Delete Drill String
 */
export const deleteDrillString = async (req, res) => {
  try {
    const existing = await DrillString.findById(req.params.id);
    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Drill String not found"
      });
    }

    const { reportId } = resolveScope(req, existing);
    if (reportId && toText(existing.reportId) !== reportId) {
      return res.status(404).json({
        success: false,
        message: "Drill String not found for this report"
      });
    }

    await DrillString.findByIdAndDelete(req.params.id);

    res.status(200).json({
      success: true,
      message: "Deleted Successfully"
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};


/**
 * @desc Update Drill String Entry
 */
export const updateDrillString = async (req, res) => {
  try {
    const existing = await DrillString.findById(req.params.id);
    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Drill String not found"
      });
    }

    const { wellId, reportId, reportNo } = resolveScope(req, existing);
    const { description, od, weightPpf, id, grade, length, sortOrder } =
      req.body;

    if (reportId && toText(existing.reportId) !== reportId) {
      return res.status(404).json({
        success: false,
        message: "Drill String not found for this report"
      });
    }

    existing.wellId = wellId || null;
    existing.reportId = reportId || null;
    existing.reportNo = reportId ? reportNo : "";
    existing.description = description;
    existing.od = Number(od || 0);
    existing.weightPpf = Number(weightPpf || 0);
    existing.id = Number(id || 0);
    existing.grade = grade;
    existing.length = Number(length || 0);
    existing.sortOrder = toSortOrder(sortOrder);

    const drill = await existing.save();

    res.status(200).json({
      success: true,
      message: "Drill String Updated Successfully",
      data: drill
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
