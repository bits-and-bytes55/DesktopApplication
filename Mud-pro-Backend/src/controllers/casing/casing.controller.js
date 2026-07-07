import Casing from "../../modules/casing/casing.model.js";

const CASED_HOLE_TOC_MARKER = "__cased_hole__";

const getWellId = (req) =>
  String(req.params.wellId ?? req.body.wellId ?? req.query.wellId ?? "").trim();
const getReportId = (req) =>
  String(req.query.reportId ?? req.body?.reportId ?? "").trim();
const toText = (value) => String(value ?? "").trim();



const buildFilter = ({ wellId, reportId }) => {
  if (!wellId) return null;
  if (reportId) {
    return {
      wellId,
      $or: [
        { toc: CASED_HOLE_TOC_MARKER, reportId },
        { toc: { $ne: CASED_HOLE_TOC_MARKER }, reportId: "" },
        { toc: { $ne: CASED_HOLE_TOC_MARKER }, reportId: { $exists: false } },
      ],
    };
  }
  return {
    wellId,
    $or: [
      { toc: { $ne: CASED_HOLE_TOC_MARKER }, reportId: "" },
      { toc: { $ne: CASED_HOLE_TOC_MARKER }, reportId: { $exists: false } },
    ],
  };
};

const toSortOrder = (value) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};

const normalizeCasingKey = (casing) =>
  [
    casing?.description,
    casing?.type,
    casing?.shoe,
  ]
    .map((value) => String(value ?? "").trim().toLowerCase())
    .join("|");

const dedupeGlobalCasings = (casings = []) => {
  const byKey = new Map();
  for (const casing of casings) {
    const key = normalizeCasingKey(casing);
    if (!key.replaceAll("|", "")) continue;

    const existing = byKey.get(key);
    if (!existing) {
      byKey.set(key, casing);
      continue;
    }

    const currentTime = new Date(casing?.createdAt ?? 0).getTime();
    const existingTime = new Date(existing?.createdAt ?? 0).getTime();
    if (currentTime < existingTime) {
      byKey.set(key, casing);
    }
  }

  return [...byKey.values()].sort((left, right) => {
    const orderDiff = toSortOrder(left?.sortOrder) - toSortOrder(right?.sortOrder);
    if (orderDiff !== 0) return orderDiff;
    return new Date(left?.createdAt ?? 0).getTime() - new Date(right?.createdAt ?? 0).getTime();
  });
};

export const getAllCasings = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = getReportId(req);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const filter = buildFilter({ wellId, reportId });
    const casings = await Casing.find(filter).sort({
      sortOrder: 1,
      createdAt: 1,
      _id: 1,
    });
    res.status(200).json({
      success: true,
      data: reportId ? casings : dedupeGlobalCasings(casings),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const addCasing = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = getReportId(req);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const isCasedHole = toText(req.body.toc) === CASED_HOLE_TOC_MARKER;
    const newCasing = await Casing.create({
      ...req.body,
      wellId,
      reportId: isCasedHole ? reportId : "",
      toc: isCasedHole ? CASED_HOLE_TOC_MARKER : req.body.toc,
      sortOrder: toSortOrder(req.body.sortOrder),
    });

    res.status(201).json({ success: true, data: newCasing });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const updateCasing = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = getReportId(req);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const isCasedHole = toText(req.body.toc) === CASED_HOLE_TOC_MARKER;
    const updatedCasing = await Casing.findOneAndUpdate(
      {
        _id: req.params.id,
        wellId,
        ...(isCasedHole && reportId ? { reportId } : {}),
      },
      {
        ...req.body,
        wellId,
        reportId: isCasedHole ? reportId : "",
        toc: isCasedHole ? CASED_HOLE_TOC_MARKER : req.body.toc,
        sortOrder: toSortOrder(req.body.sortOrder),
      },
      { returnDocument: "after" }
    );

    if (!updatedCasing) {
      return res
        .status(404)
        .json({ success: false, message: "Casing not found" });
    }
    res.status(200).json({ success: true, data: updatedCasing });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const deleteCasing = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = getReportId(req);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const filter = {
      _id: req.params.id,
      wellId,
      ...(reportId
        ? {
            $or: [
              { toc: CASED_HOLE_TOC_MARKER, reportId },
              { toc: { $ne: CASED_HOLE_TOC_MARKER } },
            ],
          }
        : {}),
    };

    const deletedCasing = await Casing.findOneAndDelete(filter);
    if (!deletedCasing) {
      return res
        .status(404)
        .json({ success: false, message: "Casing not found" });
    }
    res
      .status(200)
      .json({ success: true, message: "Casing deleted successfully" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
