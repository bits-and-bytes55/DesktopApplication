import Service from "../../../modules/ConsumeServices/Services/Service.js";
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

export const createService = async (req, res) => {
  try {
    const newService = await Service.create(buildPayload(req));

    res.status(201).json({
      success: true,
      message: "Service created successfully",
      data: newService,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const getAllServices = async (req, res) => {
  try {
    const { filter } = getScope(req);
    const services = await Service.find(filter).sort({
      createdAt: 1,
      _id: 1,
    });

    res.status(200).json({
      success: true,
      count: services.length,
      data: services,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const getServiceById = async (req, res) => {
  try {
    const service = await Service.findById(req.params.id);

    if (!service) {
      return res.status(404).json({
        success: false,
        message: "Service not found",
      });
    }

    res.status(200).json({
      success: true,
      data: service,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const updateService = async (req, res) => {
  try {
    const existing = await Service.findOne(scopedIdFilter(req));

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Service not found",
      });
    }

    const updatedService = await Service.findOneAndUpdate(
      scopedIdFilter(req),
      buildPayload(req, existing),
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Service updated successfully",
      data: updatedService,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const deleteService = async (req, res) => {
  try {
    const service = await Service.findOneAndDelete(scopedIdFilter(req));

    if (!service) {
      return res.status(404).json({
        success: false,
        message: "Service not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Service deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
