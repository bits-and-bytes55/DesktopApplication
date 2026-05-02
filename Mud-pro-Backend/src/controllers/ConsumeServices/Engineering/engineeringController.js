import Engineering from "../../../modules/ConsumeServices/Engineers/Engineering.js";
import {
  buildScopedFilter,
  readReportId,
  readWellId,
  toText,
} from "../../../utils/reportScope.js";

const getScope = (req) => {
  const wellId = readWellId(req);
  const reportId = readReportId(req);

  if (wellId) {
    return { wellId, reportId, filter: buildScopedFilter(wellId, reportId) };
  }

  return {
    wellId,
    reportId,
    filter: reportId ? { reportId } : {},
  };
};

const buildPayload = (req, existing = {}) => {
  const usage = Number(req.body.usage ?? existing.usage ?? 0);
  const price = Number(req.body.price ?? existing.price ?? 0);

  return {
    ...req.body,
    wellId: readWellId(req) || toText(existing.wellId),
    reportId: readReportId(req) || toText(existing.reportId),
    cost: usage * price,
  };
};

const scopedIdFilter = (req) => {
  const wellId = readWellId(req);
  const reportId = readReportId(req);
  return {
    _id: req.params.id,
    ...(wellId ? { wellId } : {}),
    ...(reportId ? { reportId } : {}),
  };
};

export const createEngineering = async (req, res) => {
  try {
    const newEngineering = await Engineering.create(buildPayload(req));

    res.status(201).json({
      success: true,
      message: "Engineering created successfully",
      data: newEngineering,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const getAllEngineering = async (req, res) => {
  try {
    const { filter } = getScope(req);
    const records = await Engineering.find(filter).sort({
      createdAt: 1,
      _id: 1,
    });

    res.status(200).json({
      success: true,
      count: records.length,
      data: records,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const getEngineeringById = async (req, res) => {
  try {
    const record = await Engineering.findById(req.params.id);

    if (!record) {
      return res.status(404).json({
        success: false,
        message: "Engineering record not found",
      });
    }

    res.status(200).json({
      success: true,
      data: record,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const updateEngineering = async (req, res) => {
  try {
    const existing = await Engineering.findOne(scopedIdFilter(req));

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Engineering record not found",
      });
    }

    const updatedRecord = await Engineering.findOneAndUpdate(
      scopedIdFilter(req),
      buildPayload(req, existing),
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Engineering updated successfully",
      data: updatedRecord,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const deleteEngineering = async (req, res) => {
  try {
    const record = await Engineering.findOneAndDelete(scopedIdFilter(req));

    if (!record) {
      return res.status(404).json({
        success: false,
        message: "Engineering record not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Engineering deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
