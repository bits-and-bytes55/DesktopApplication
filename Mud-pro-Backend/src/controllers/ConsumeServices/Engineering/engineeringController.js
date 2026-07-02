import Engineering from "../../../modules/ConsumeServices/Engineers/Engineering.js";
import {
  buildScopedFilter,
  readReportId,
  readWellId,
  toText,
} from "../../../utils/reportScope.js";
import {
  operationInstancePayload,
  readOperationInstanceKey,
  withOperationInstanceScope,
} from "../../../utils/operationInstanceScope.js";

const LEGACY_OPERATION_INSTANCE_KEY = "consumeServices::legacy0";

const getScope = (req) => {
  const wellId = readWellId(req);
  const reportId = readReportId(req);

  if (wellId) {
    return {
      wellId,
      reportId,
      filter: withOperationInstanceScope(
        buildScopedFilter(wellId, reportId),
        readOperationInstanceKey(req),
        LEGACY_OPERATION_INSTANCE_KEY
      ),
    };
  }

  return {
    wellId,
    reportId,
    filter: withOperationInstanceScope(
      reportId ? { reportId } : {},
      readOperationInstanceKey(req),
      LEGACY_OPERATION_INSTANCE_KEY
    ),
  };
};

const buildPayload = (req, existing = {}) => {
  const usage = Number(req.body.usage ?? existing.usage ?? 0);
  const price = Number(req.body.price ?? existing.price ?? 0);

  return {
    ...req.body,
    wellId: readWellId(req) || toText(existing.wellId),
    reportId: readReportId(req) || toText(existing.reportId),
    operationInstanceKey: operationInstancePayload(req, existing),
    cost: usage * price,
  };
};

const scopedIdFilter = (req) => {
  const wellId = readWellId(req);
  const reportId = readReportId(req);
  const filter = {
    _id: req.params.id,
    ...(wellId ? { wellId } : {}),
    ...(reportId ? { reportId } : {}),
  };
  return withOperationInstanceScope(
    filter,
    readOperationInstanceKey(req),
    LEGACY_OPERATION_INSTANCE_KEY
  );
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
      { returnDocument: "after" }
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
