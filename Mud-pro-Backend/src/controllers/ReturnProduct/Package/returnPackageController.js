import ReturnPackage from "../../../modules/ReturnProduct/Package/ReturnPackage.js";
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

const scopedIdFilter = (req) => {
  const wellId = readWellId(req);
  const reportId = readReportId(req);
  return {
    _id: req.params.id,
    ...(wellId ? { wellId } : {}),
    ...(reportId ? { reportId } : {}),
  };
};

/**
 * @desc    Create Return Package
 */
export const createReturnPackage = async (req, res) => {
  try {
    const newReturnPackage = await ReturnPackage.create({
      ...buildPayload(req),
    });

    res.status(201).json({
      success: true,
      message: "Return Package created successfully",
      data: newReturnPackage,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Get All Return Packages
 */
export const getAllReturnPackages = async (req, res) => {
  try {
    const { filter } = getScope(req);
    const packages = await ReturnPackage.find(filter).sort({
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
 * @desc    Get Single Return Package
 */
export const getReturnPackageById = async (req, res) => {
  try {
    const pkg = await ReturnPackage.findById(req.params.id);

    if (!pkg) {
      return res.status(404).json({
        success: false,
        message: "Return Package not found",
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
 * @desc    Update Return Package
 */
export const updateReturnPackage = async (req, res) => {
  try {
    const existing = await ReturnPackage.findOne(scopedIdFilter(req));

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Return Package not found",
      });
    }

    const updatedPackage = await ReturnPackage.findOneAndUpdate(
      scopedIdFilter(req),
      buildPayload(req, existing),
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Return Package updated successfully",
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
 * @desc    Delete Return Package
 */
export const deleteReturnPackage = async (req, res) => {
  try {
    const deleted = await ReturnPackage.findOneAndDelete(scopedIdFilter(req));

    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: "Return Package not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Return Package deleted successfully",
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
