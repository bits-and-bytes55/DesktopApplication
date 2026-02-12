import ConsumeProduct from "../../modules/Consumeproduct/ConsumeProduct.js"

/**
 * @desc    Create Consume Product
 */
/**
 * @desc    Create Consume Product (With Auto Calculation)
 */
export const createConsumeProduct = async (req, res) => {
  try {
    let {
      initial = 0,
      adjust = 0,
      used = 0,
      price = 0,
      numberOfBags = 0,
      weightPerBag = 0,
      sg = 1
    } = req.body;

    // 🔥 Auto Calculations
    const final = Number(initial) + Number(adjust) - Number(used);
    const cost = Number(used) * Number(price);

    // 🔥 Volume Calculation (KG → BBL)
    // Formula: volumeBbl = (N × Wb) / (SG × 158.987)
    const totalWeight = Number(numberOfBags) * Number(weightPerBag);

    let volumeBbl = 0;

    if (Number(sg) > 0) {
      volumeBbl = totalWeight / (Number(sg) * 158.987);
    }

    const consumeProduct = await ConsumeProduct.create({
      ...req.body,
      final,
      cost,
      volumeBbl: +volumeBbl.toFixed(3) // 3 decimal precision
    });

    res.status(201).json({
      success: true,
      message: "Consume Product created successfully",
      data: consumeProduct,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};




/**
 * @desc    Get All Consume Products
 */
export const getAllConsumeProducts = async (req, res) => {
  try {
    const products = await ConsumeProduct.find().populate("product");

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
 * @desc    Get Single Consume Product
 */
export const getConsumeProductById = async (req, res) => {
  try {
    const product = await ConsumeProduct.findById(req.params.id).populate("product");

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Consume Product not found",
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
 * @desc    Update Consume Product (With Recalculation)
 */
export const updateConsumeProduct = async (req, res) => {
  try {
    const existing = await ConsumeProduct.findById(req.params.id);

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Consume Product not found",
      });
    }

    // Merge old + new values
    const initial = req.body.initial ?? existing.initial;
    const adjust  = req.body.adjust ?? existing.adjust;
    const used    = req.body.used ?? existing.used;
    const price   = req.body.price ?? existing.price;

    // 🔥 Recalculate
    const final = Number(initial) + Number(adjust) - Number(used);
    const cost = Number(used) * Number(price);

    const updatedProduct = await ConsumeProduct.findByIdAndUpdate(
      req.params.id,
      {
        ...req.body,
        final,
        cost,
      },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Consume Product updated successfully",
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
 * @desc    Delete Consume Product
 */
export const deleteConsumeProduct = async (req, res) => {
  try {
    const product = await ConsumeProduct.findByIdAndDelete(req.params.id);

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Consume Product not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Consume Product deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
