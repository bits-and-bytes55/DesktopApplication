import Package from "../../../modules/ConsumeServices/Package/Package.js";
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
  const initial = Number(req.body.initial ?? existing.initial ?? 0);
  const adjust = Number(req.body.adjust ?? existing.adjust ?? 0);
  const used = Number(req.body.used ?? existing.used ?? 0);
  const price = Number(req.body.price ?? existing.price ?? 0);

  return {
    ...req.body,
    wellId: readWellId(req) || toText(existing.wellId),
    reportId: readReportId(req) || toText(existing.reportId),
    operationInstanceKey: operationInstancePayload(req, existing),
    final: initial + adjust - used,
    cost: used * price,
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

export const createPackage = async (req, res) => {
  try {
    const newPackage = await Package.create(buildPayload(req));

    res.status(201).json({
      success: true,
      message: "Package created successfully",
      data: newPackage,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const getAllPackages = async (req, res) => {
  try {
    const { filter } = getScope(req);
    const packages = await Package.find(filter).sort({
      createdAt: 1,
      _id: 1,
    });

    res.status(200).json({
      success: true,
      count: packages.length,
      data: packages,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const getPackageById = async (req, res) => {
  try {
    const pkg = await Package.findById(req.params.id);

    if (!pkg) {
      return res.status(404).json({
        success: false,
        message: "Package not found",
      });
    }

    res.status(200).json({
      success: true,
      data: pkg,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const updatePackage = async (req, res) => {
  try {
    const existing = await Package.findOne(scopedIdFilter(req));

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Package not found",
      });
    }

    const updatedPackage = await Package.findOneAndUpdate(
      scopedIdFilter(req),
      buildPayload(req, existing),
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Package updated successfully",
      data: updatedPackage,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const deletePackage = async (req, res) => {
  try {
    const pkg = await Package.findOneAndDelete(scopedIdFilter(req));

    if (!pkg) {
      return res.status(404).json({
        success: false,
        message: "Package not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Package deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
