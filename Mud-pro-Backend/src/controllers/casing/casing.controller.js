import Casing from "../../modules/casing/casing.model.js";

const getWellId = (req) =>
  String(req.params.wellId ?? req.body.wellId ?? req.query.wellId ?? "").trim();



const buildFilter = ({ wellId }) => {
  if (!wellId) return null;
  return { wellId };
};

const toSortOrder = (value) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};

export const getAllCasings = async (req, res) => {
  try {
    const wellId = getWellId(req);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const filter = buildFilter({ wellId });
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

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const newCasing = await Casing.create({
      ...req.body,
      wellId,
      reportId: "",
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
      },
      {
        ...req.body,
        wellId,
        reportId: "",
        sortOrder: toSortOrder(req.body.sortOrder),
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

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const filter = {
      _id: req.params.id,
      wellId,
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
