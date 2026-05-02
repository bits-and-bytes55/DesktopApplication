import Casing from "../../modules/casing/casing.model.js";

const getWellId = (req) =>
  String(req.params.wellId ?? req.body.wellId ?? req.query.wellId ?? "").trim();
const getReportId = (req) =>
  String(req.query.reportId ?? req.body.reportId ?? "").trim();
const toText = (value) => String(value ?? "").trim();

const buildFilter = ({ wellId, reportId }) => {
  if (!wellId) return null;
  if (reportId) return { wellId, reportId };
  return { wellId };
};

const toSortOrder = (value) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
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
    res.status(200).json({ success: true, data: casings });
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

    const newCasing = await Casing.create({
      ...req.body,
      wellId,
      reportId,
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

    const updatedCasing = await Casing.findOneAndUpdate(
      {
        _id: req.params.id,
        wellId,
        ...(reportId ? { reportId } : {}),
      },
      {
        ...req.body,
        wellId,
        sortOrder: toSortOrder(req.body.sortOrder),
        ...(req.body.reportId !== undefined || reportId
          ? { reportId: toText(req.body.reportId ?? reportId) }
          : {}),
      },
      { new: true }
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
      ...(reportId ? { reportId } : {}),
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
