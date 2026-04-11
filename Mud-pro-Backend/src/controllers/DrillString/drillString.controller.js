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
    .sort({ createdAt: 1, _id: 1 })
    .lean();
};

const loadLegacyDrillStrings = async (wellId) => {
  if (wellId) {
    const wellScoped = await DrillString.find(legacyWellFilter(wellId))
      .sort({ createdAt: 1, _id: 1 })
      .lean();

    if (wellScoped.length > 0) {
      return wellScoped;
    }
  }

  return DrillString.find(legacyGlobalFilter())
    .sort({ createdAt: 1, _id: 1 })
    .lean();
};

const loadDisplayDrillStrings = async ({ wellId, reportId }) => {
  if (wellId && reportId) {
    const scoped = await loadScopedDrillStrings(wellId, reportId);
    if (scoped.length > 0) {
      return scoped;
    }
    return loadLegacyDrillStrings(wellId);
  }

  if (wellId) {
    return loadLegacyDrillStrings(wellId);
  }

  if (reportId) {
    return DrillString.find({ reportId })
      .sort({ createdAt: 1, _id: 1 })
      .lean();
  }

  return DrillString.find({})
    .sort({ createdAt: 1, _id: 1 })
    .lean();
};

/**
 * @desc Create Drill String Entry
 */
export const createDrillString = async (req, res) => {
  try {
    const { wellId, reportId, reportNo } = resolveScope(req);
    const { description, od, weightPpf, id, grade, length } = req.body;

    const drill = await DrillString.create({
      wellId: wellId || null,
      reportId: reportId || null,
      reportNo: reportId ? reportNo : "",
      description,
      od: Number(od || 0),
      weightPpf: Number(weightPpf || 0),
      id: Number(id || 0),
      grade,
      length: Number(length || 0)
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
