import mongoose from "mongoose";
import FormationConfig from "../../modules/formation/formation.model.js";
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
  FormationConfig.findOne(legacyFilter(wellId))
    .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
    .lean();

const loadScopedDoc = (wellId, reportId) => {
  if (!wellId || !reportId) return null;
  return FormationConfig.findOne({ wellId, reportId })
    .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
    .lean();
};

const loadDisplayDoc = async ({ wellId, reportId }) => {
  if (wellId && reportId) {
    const scoped = await loadScopedDoc(wellId, reportId);
    if (scoped) return scoped;
    return loadLegacyDoc(wellId);
  }

  if (wellId) {
    return loadLegacyDoc(wellId);
  }

  if (reportId) {
    return FormationConfig.findOne({ reportId })
      .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
      .lean();
  }

  return null;
};

const normalizeMode = (value) => {
  const text = toText(value);
  if (["Density", "Gradient", "Pressure"].includes(text)) {
    return text;
  }
  return "Gradient";
};

const sanitizeRow = (row = {}, index = 0) => ({
  rowNumber: Number(row.rowNumber) || index + 1,
  description: toText(row.description),
  tvd: toText(row.tvd),
  porePpg: toText(row.porePpg),
  poreGrad: toText(row.poreGrad),
  porePsi: toText(row.porePsi),
  fracPpg: toText(row.fracPpg),
  fracGrad: toText(row.fracGrad),
  fracPsi: toText(row.fracPsi),
  lithology: toText(row.lithology),
});

const sanitizeRows = (rows = []) =>
  Array.isArray(rows) ? rows.slice(0, 23).map(sanitizeRow) : [];

const buildPayload = ({
  body = {},
  existing = {},
  wellId,
  reportId,
  reportNo,
}) => ({
  ...cleanClone(existing),
  wellId: wellId || toText(existing.wellId),
  reportId: reportId || "",
  reportNo: reportId ? reportNo : "",
  poreFromTop:
    typeof body.poreFromTop === "boolean"
      ? body.poreFromTop
      : Boolean(existing.poreFromTop ?? true),
  mode: normalizeMode(body.mode ?? existing.mode),
  rows: sanitizeRows(body.rows ?? existing.rows ?? []),
});

const blankResponse = () => ({
  poreFromTop: true,
  mode: "Gradient",
  rows: [],
});

const ensureScopedDoc = async ({ wellId, reportId, reportNo }) => {
  if (!wellId || !reportId) return null;
  const scoped = await loadScopedDoc(wellId, reportId);
  if (scoped) return scoped;

  const legacy = await loadLegacyDoc(wellId);
  if (!legacy) return null;

  const created = await FormationConfig.create({
    ...cleanClone(legacy),
    wellId,
    reportId,
    reportNo,
  });
  return created.toObject();
};

export const getFormationConfig = async (req, res) => {
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
    console.error("Error fetching formation config:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch formation config",
      error: error.message,
    });
  }
};

export const saveFormationConfig = async (req, res) => {
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
      ? await FormationConfig.findByIdAndUpdate(existing._id, payload, {
          returnDocument: "after",
          runValidators: true,
        })
      : await FormationConfig.create(payload);

    return res.status(existing?._id ? 200 : 201).json({
      success: true,
      message: existing?._id
        ? "Formation updated successfully"
        : "Formation created successfully",
      data: saved,
    });
  } catch (error) {
    console.error("Error saving formation config:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to save formation config",
      error: error.message,
    });
  }
};

export const deleteFormationConfig = async (req, res) => {
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
        message: "Formation config not found",
      });
    }

    await FormationConfig.findByIdAndDelete(existing._id);
    return res.status(200).json({
      success: true,
      message: "Formation config deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting formation config:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete formation config",
      error: error.message,
    });
  }
};
