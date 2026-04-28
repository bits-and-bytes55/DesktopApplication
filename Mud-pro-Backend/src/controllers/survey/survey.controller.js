import mongoose from "mongoose";
import SurveyConfig from "../../modules/survey/survey.model.js";
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

const resolveScope = (req, existing = {}) => {
  const wellId = normalizeObjectId(
    req.params?.wellId ?? readWellId(req) ?? existing.wellId
  );
  const reportId = normalizeObjectId(readReportId(req) || existing.reportId);
  const reportNo = reportId
    ? toText(readReportNo(req) || existing.reportNo)
    : "";
  return { wellId, reportId, reportNo };
};

const legacyFilter = (wellId) => ({
  ...(wellId ? { wellId } : {}),
  $or: [{ reportId: { $exists: false } }, { reportId: null }, { reportId: "" }],
});

const loadLegacyDoc = (wellId) =>
  SurveyConfig.findOne(legacyFilter(wellId))
    .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
    .lean();

const loadScopedDoc = (wellId, reportId) => {
  if (!wellId || !reportId) return null;
  return SurveyConfig.findOne({ wellId, reportId })
    .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
    .lean();
};

const loadDisplayDoc = async ({ wellId, reportId }) => {
  if (wellId && reportId) {
    const scoped = await loadScopedDoc(wellId, reportId);
    if (scoped) return scoped;
    return loadLegacyDoc(wellId);
  }
  if (wellId) return loadLegacyDoc(wellId);
  if (reportId) {
    return SurveyConfig.findOne({ reportId })
      .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
      .lean();
  }
  return null;
};

const sanitizeRow = (row = {}, index = 0) => ({
  rowNumber: Number(row.rowNumber) || index + 1,
  md: toText(row.md),
  inc: toText(row.inc),
  azi: toText(row.azi),
  tvd: toText(row.tvd),
  vsec: toText(row.vsec),
  northSouth: toText(row.northSouth),
  eastWest: toText(row.eastWest),
  dogleg: toText(row.dogleg),
});

const sanitizeRows = (rows = []) =>
  Array.isArray(rows) ? rows.slice(0, 64).map(sanitizeRow) : [];

const sanitizeAnnotation = (row = {}, index = 0) => ({
  rowNumber: Number(row.rowNumber) || index + 1,
  md: toText(row.md),
  annotation: toText(row.annotation),
  symbol: toText(row.symbol),
});

const sanitizeAnnotations = (rows = []) =>
  Array.isArray(rows) ? rows.slice(0, 32).map(sanitizeAnnotation) : [];

const blankResponse = () => ({
  plannedSurvey: true,
  annotationEnabled: true,
  projectAziEnabled: false,
  projectAzi: "",
  rows: [],
  annotations: [],
});

const buildPayload = ({ body = {}, existing = {}, wellId, reportId, reportNo }) => ({
  ...cleanClone(existing),
  wellId: wellId || toText(existing.wellId),
  reportId: reportId || "",
  reportNo: reportId ? reportNo : "",
  plannedSurvey:
    typeof body.plannedSurvey === "boolean"
      ? body.plannedSurvey
      : Boolean(existing.plannedSurvey ?? true),
  annotationEnabled:
    typeof body.annotationEnabled === "boolean"
      ? body.annotationEnabled
      : Boolean(existing.annotationEnabled ?? true),
  projectAziEnabled:
    typeof body.projectAziEnabled === "boolean"
      ? body.projectAziEnabled
      : Boolean(existing.projectAziEnabled ?? false),
  projectAzi: toText(body.projectAzi ?? existing.projectAzi),
  rows: sanitizeRows(body.rows ?? existing.rows ?? []),
  annotations: sanitizeAnnotations(body.annotations ?? existing.annotations ?? []),
});

const ensureScopedDoc = async ({ wellId, reportId, reportNo }) => {
  if (!wellId || !reportId) return null;
  const scoped = await loadScopedDoc(wellId, reportId);
  if (scoped) return scoped;
  const legacy = await loadLegacyDoc(wellId);
  if (!legacy) return null;
  const created = await SurveyConfig.create({
    ...cleanClone(legacy),
    wellId,
    reportId,
    reportNo,
  });
  return created.toObject();
};

export const getSurveyConfig = async (req, res) => {
  try {
    const { wellId, reportId } = resolveScope(req);
    if (req.params?.wellId && !wellId) {
      return res.status(400).json({
        success: false,
        message: "Invalid well ID",
      });
    }
    const config = await loadDisplayDoc({ wellId, reportId });
    return res.status(200).json({
      success: true,
      data: config || blankResponse(),
    });
  } catch (error) {
    console.error("Error fetching survey config:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch survey config",
      error: error.message,
    });
  }
};

export const saveSurveyConfig = async (req, res) => {
  try {
    const scope = resolveScope(req);
    if (req.params?.wellId && !scope.wellId) {
      return res.status(400).json({
        success: false,
        message: "Invalid well ID",
      });
    }

    let existing = scope.reportId
      ? await loadScopedDoc(scope.wellId, scope.reportId)
      : await loadLegacyDoc(scope.wellId);

    if (!existing && scope.reportId) {
      existing = await ensureScopedDoc({
        wellId: scope.wellId,
        reportId: scope.reportId,
        reportNo: scope.reportNo,
      });
    }

    const payload = buildPayload({
      body: req.body,
      existing: existing ?? {},
      wellId: scope.wellId,
      reportId: scope.reportId,
      reportNo: scope.reportNo,
    });

    const saved = existing?._id
      ? await SurveyConfig.findByIdAndUpdate(existing._id, payload, {
          new: true,
          runValidators: true,
        })
      : await SurveyConfig.create(payload);

    return res.status(existing?._id ? 200 : 201).json({
      success: true,
      message: existing?._id
        ? "Survey updated successfully"
        : "Survey created successfully",
      data: saved,
    });
  } catch (error) {
    console.error("Error saving survey config:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to save survey config",
      error: error.message,
    });
  }
};

export const deleteSurveyConfig = async (req, res) => {
  try {
    const scope = resolveScope(req);
    if (req.params?.wellId && !scope.wellId) {
      return res.status(400).json({
        success: false,
        message: "Invalid well ID",
      });
    }

    const existing = scope.reportId
      ? await loadScopedDoc(scope.wellId, scope.reportId)
      : await loadLegacyDoc(scope.wellId);

    if (!existing?._id) {
      return res.status(404).json({
        success: false,
        message: "Survey config not found",
      });
    }

    await SurveyConfig.findByIdAndDelete(existing._id);
    return res.status(200).json({
      success: true,
      message: "Survey config deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting survey config:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete survey config",
      error: error.message,
    });
  }
};
