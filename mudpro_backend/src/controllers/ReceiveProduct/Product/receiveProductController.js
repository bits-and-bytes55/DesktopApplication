import ReceiveProduct from "../../../modules/ReceiveProduct/Product/ReceiveProduct.js";

/**
 * @desc    Create Receive Product
 */
export const createReceiveProduct = async (req, res) => {
  try {
    const newProduct = await ReceiveProduct.create({
      ...req.body,
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
    const products = await ReceiveProduct.find();

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
    const updatedProduct = await ReceiveProduct.findByIdAndUpdate(
      req.params.id,
      {
        ...req.body,
      },
      { new: true }
    );

    if (!updatedProduct) {
      return res.status(404).json({
        success: false,
        message: "Receive Product not found",
      });
    }

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
    const deleted = await ReceiveProduct.findByIdAndDelete(req.params.id);

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
