import ReceivePackage from "../../../modules/ReceiveProduct/Package/ReceivePackage.js";
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

const buildPayload = (req, existing = {}) => ({
  ...req.body,
  wellId: readWellId(req) || toText(existing.wellId),
  reportId: readReportId(req) || toText(existing.reportId),
});

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
    const existing = await ReceivePackage.findById(req.params.id);

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Receive Package not found",
      });
    }

    const updatedPackage = await ReceivePackage.findByIdAndUpdate(
      req.params.id,
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
    const deleted = await ReceivePackage.findByIdAndDelete(req.params.id);

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
