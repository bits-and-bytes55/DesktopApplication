import ReceiveProduct from "../../../modules/ReceiveProduct/Product/ReceiveProduct.js";
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
 * @desc    Create Receive Product
 */
export const createReceiveProduct = async (req, res) => {
  try {
    const newProduct = await ReceiveProduct.create({
      ...buildPayload(req),
    });

    res.status(201).json({
      success: true,
      message: "Receive Product created successfully",
      data: newProduct,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Get All Receive Products
 */
export const getAllReceiveProducts = async (req, res) => {
  try {
    const { filter } = getScope(req);
    const products = await ReceiveProduct.find(filter).sort({
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
 * @desc    Get Single Receive Product
 */
export const getReceiveProductById = async (req, res) => {
  try {
    const product = await ReceiveProduct.findById(req.params.id);

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Receive Product not found",
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
 * @desc    Update Receive Product
 */
export const updateReceiveProduct = async (req, res) => {
  try {
    const existing = await ReceiveProduct.findOne(scopedIdFilter(req));

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Receive Product not found",
      });
    }

    const updatedProduct = await ReceiveProduct.findOneAndUpdate(
      scopedIdFilter(req),
      buildPayload(req, existing),
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Receive Product updated successfully",
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
 * @desc    Delete Receive Product
 */
export const deleteReceiveProduct = async (req, res) => {
  try {
    const deleted = await ReceiveProduct.findOneAndDelete(scopedIdFilter(req));

    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: "Receive Product not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Receive Product deleted successfully",
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
