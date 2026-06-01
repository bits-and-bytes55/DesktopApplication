import ReturnProduct from "../../../modules/ReturnProduct/Product/ReturnProduct.js";
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

const LEGACY_OPERATION_INSTANCE_KEY = "returnProduct::legacy0";

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
 * @desc    Create Return Product
 */
export const createReturnProduct = async (req, res) => {
  try {
    const newReturnProduct = await ReturnProduct.create({
      ...buildPayload(req),
    });

    res.status(201).json({
      success: true,
      message: "Return Product created successfully",
      data: newReturnProduct,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Get All Return Products
 */
export const getAllReturnProducts = async (req, res) => {
  try {
    const { filter } = getScope(req);
    const products = await ReturnProduct.find(filter).sort({
      createdAt: 1,
      _id: 1,
    });

    res.status(200).json({
      success: true,
      count: products.length,
      data: products,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Get Single Return Product
 */
export const getReturnProductById = async (req, res) => {
  try {
    const product = await ReturnProduct.findById(req.params.id);

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Return Product not found",
      });
    }

    res.status(200).json({
      success: true,
      data: product,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Update Return Product
 */
export const updateReturnProduct = async (req, res) => {
  try {
    const existing = await ReturnProduct.findOne(scopedIdFilter(req));

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Return Product not found",
      });
    }

    const updatedProduct = await ReturnProduct.findOneAndUpdate(
      scopedIdFilter(req),
      buildPayload(req, existing),
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Return Product updated successfully",
      data: updatedProduct,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Delete Return Product
 */
export const deleteReturnProduct = async (req, res) => {
  try {
    const deleted = await ReturnProduct.findOneAndDelete(scopedIdFilter(req));

    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: "Return Product not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Return Product deleted successfully",
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
