import ReturnProduct from "../../../modules/ReturnProduct/Product/ReturnProduct.js";

/**
 * @desc    Create Return Product
 */
export const createReturnProduct = async (req, res) => {
  try {
    const newReturnProduct = await ReturnProduct.create({
      ...req.body,
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
    const products = await ReturnProduct.find();

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
    const updatedProduct = await ReturnProduct.findByIdAndUpdate(
      req.params.id,
      {
        ...req.body,
      },
      { new: true }
    );

    if (!updatedProduct) {
      return res.status(404).json({
        success: false,
        message: "Return Product not found",
      });
    }

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
    const deleted = await ReturnProduct.findByIdAndDelete(req.params.id);

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
