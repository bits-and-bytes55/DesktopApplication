import ReceivePackage from "../../../modules/ReceiveProduct/Package/ReceivePackage.js";
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

const LEGACY_OPERATION_INSTANCE_KEY = "receiveProduct::legacy0";

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

const buildPayload = (req, existing = {}) => ({
  ...req.body,
  wellId: readWellId(req) || toText(existing.wellId),
  reportId: readReportId(req) || toText(existing.reportId),
  operationInstanceKey: operationInstancePayload(req, existing),
});

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

/**
 * @desc    Create Receive Package
 */
export const createReceivePackage = async (req, res) => {
  try {
    const newPackage = await ReceivePackage.create({
      ...buildPayload(req),
    });

    res.status(201).json({
      success: true,
      message: "Receive Package created successfully",
      data: newPackage,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Get All Receive Packages
 */
export const getAllReceivePackages = async (req, res) => {
  try {
    const { filter } = getScope(req);
    const packages = await ReceivePackage.find(filter).sort({
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


/**
 * @desc    Get Single Receive Package
 */
export const getReceivePackageById = async (req, res) => {
  try {
    const pkg = await ReceivePackage.findById(req.params.id);

    if (!pkg) {
      return res.status(404).json({
        success: false,
        message: "Receive Package not found",
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


/**
 * @desc    Update Receive Package
 */
export const updateReceivePackage = async (req, res) => {
  try {
    const existing = await ReceivePackage.findOne(scopedIdFilter(req));

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Receive Package not found",
      });
    }

    const updatedPackage = await ReceivePackage.findOneAndUpdate(
      scopedIdFilter(req),
      buildPayload(req, existing),
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Receive Package updated successfully",
      data: updatedPackage,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Delete Receive Package
 */
export const deleteReceivePackage = async (req, res) => {
  try {
    const deleted = await ReceivePackage.findOneAndDelete(scopedIdFilter(req));

    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: "Receive Package not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Receive Package deleted successfully",
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
