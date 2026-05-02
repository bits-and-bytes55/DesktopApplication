import mongoose from "mongoose";
import WellPlan from "../../modules/wellPlan/wellPlan.model.js";
import {
  readReportId,
  readReportNo,
  readWellId,
  toText,
} from "../../utils/reportScope.js";

const PLAN_COLUMN_COUNT = 31;
const DEFAULT_SUMMARY = [
  { type: "TD", amount: "", unit: "(ft)" },
  { type: "Days", amount: "", unit: "(-)" },
  { type: "Total Cost", amount: "", unit: "(Kwd)" },
];

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

const normalizeSummary = (summary = []) =>
  DEFAULT_SUMMARY.map((item, index) => {
    const raw = Array.isArray(summary) && index < summary.length ? summary[index] : {};
    return {
      type: toText(raw.type) || item.type,
      amount: toText(raw.amount),
      unit: toText(raw.unit) || item.unit,
    };
  });

const normalizeRowValues = (values = []) => {
  const row = Array.from({ length: PLAN_COLUMN_COUNT }, () => "");
  if (!Array.isArray(values)) return row;
  const limit = Math.min(values.length, PLAN_COLUMN_COUNT);
  for (let index = 0; index < limit; index += 1) {
    row[index] = toText(values[index]);
  }
  return row;
};

const sanitizeRows = (rows = []) =>
  Array.isArray(rows)
    ? rows.map((row, index) => ({
        rowNumber: Number(row.rowNumber) || index + 1,
        values: normalizeRowValues(row.values),
      }))
    : [];

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
  WellPlan.findOne(legacyFilter(wellId))
    .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
    .lean();

const loadScopedDoc = (wellId, reportId) => {
  if (!wellId || !reportId) return null;
  return WellPlan.findOne({ wellId, reportId })
    .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
    .lean();
};

const loadDisplayDoc = async ({ wellId, reportId }) => {
  if (wellId && reportId) {
    return loadScopedDoc(wellId, reportId);
  }

  if (wellId) {
    return loadLegacyDoc(wellId);
  }

  if (reportId) {
    return WellPlan.findOne({ reportId })
      .sort({ updatedAt: -1, createdAt: -1, _id: -1 })
      .lean();
  }

  return null;
};

const blankResponse = () => ({
  summary: normalizeSummary(),
  rows: [],
});

const buildPayload = ({ body = {}, existing = {}, wellId, reportId, reportNo }) => ({
  ...cleanClone(existing),
  wellId: wellId || toText(existing.wellId),
  reportId: reportId || "",
  reportNo: reportId ? reportNo : "",
  summary: normalizeSummary(body.summary ?? existing.summary ?? []),
  rows: sanitizeRows(body.rows ?? existing.rows ?? []),
});

export const getWellPlan = async (req, res) => {
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
    console.error("Error fetching well plan:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch well plan",
      error: error.message,
    });
  }
};

export const saveWellPlan = async (req, res) => {
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

    const payload = buildPayload({
      body: req.body,
      existing: existing ?? {},
      wellId: scope.wellId,
      reportId: scope.reportId,
      reportNo: scope.reportNo,
    });

    const saved = existing?._id
      ? await WellPlan.findByIdAndUpdate(existing._id, payload, {
          new: true,
          runValidators: true,
        })
      : await WellPlan.create(payload);

    return res.status(existing?._id ? 200 : 201).json({
      success: true,
      message: existing?._id
        ? "Well plan updated successfully"
        : "Well plan created successfully",
      data: saved,
    });
  } catch (error) {
    console.error("Error saving well plan:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to save well plan",
      error: error.message,
    });
  }
};

export const deleteWellPlan = async (req, res) => {
  try {
    const { wellId, reportId } = resolveScope(req);
    if (req.params?.wellId && !wellId) {
      return res.status(400).json({
        success: false,
        message: "Invalid well ID",
      });
    }

    const target = reportId
      ? await loadScopedDoc(wellId, reportId)
      : await loadLegacyDoc(wellId);

    if (!target?._id) {
      return res.status(404).json({
        success: false,
        message: "Well plan not found",
      });
    }

    await WellPlan.findByIdAndDelete(target._id);
    return res.status(200).json({
      success: true,
      message: "Well plan deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting well plan:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete well plan",
      error: error.message,
    });
  }
};
