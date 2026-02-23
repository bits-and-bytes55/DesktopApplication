import ConsumeProduct from "../../modules/Consumeproduct/ConsumeProduct.js";

/**
 * @desc    Create Consume Product (With Auto Calculation)
 */
export const createConsumeProduct = async (req, res) => {
  try {

    // 🔥 Safe Number Conversion (Negative Allowed)
    const initial = Number(req.body.initial ?? 0);
    const adjust  = Number(req.body.adjust ?? 0);
    const used    = Number(req.body.used ?? 0);
    const price   = Number(req.body.price ?? 0);

    const numberOfBags = Number(req.body.numberOfBags ?? 0);
    const weightPerBag = Number(req.body.weightPerBag ?? 0);
    const sg           = Number(req.body.sg ?? 1);

    // 🔥 Final Calculation (Negative Allowed)
    const final = initial + adjust - used;

    // 🔥 Cost Calculation
    const cost = used * price;

    // 🔥 Volume Calculation (KG → BBL)
    // Formula: volumeBbl = (N × Wb) / (SG × 158.987)
    const totalWeight = numberOfBags * weightPerBag;

    let volumeBbl = 0;

    if (sg > 0) {
      volumeBbl = totalWeight / (sg * 158.987);
    }

    const consumeProduct = await ConsumeProduct.create({
      ...req.body,
      final,
      cost,
      volumeBbl: +volumeBbl.toFixed(3)
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

    // 🔥 Safe Merge + Number Conversion
    const initial = Number(req.body.initial ?? existing.initial ?? 0);
    const adjust  = Number(req.body.adjust  ?? existing.adjust  ?? 0);
    const used    = Number(req.body.used    ?? existing.used    ?? 0);
    const price   = Number(req.body.price   ?? existing.price   ?? 0);

    const numberOfBags = Number(req.body.numberOfBags ?? existing.numberOfBags ?? 0);
    const weightPerBag = Number(req.body.weightPerBag ?? existing.weightPerBag ?? 0);
    const sg           = Number(req.body.sg ?? existing.sg ?? 1);

    // 🔥 Recalculate Final (Negative Allowed)
    const final = initial + adjust - used;

    // 🔥 Recalculate Cost
    const cost = used * price;

    // 🔥 Recalculate Volume
    const totalWeight = numberOfBags * weightPerBag;

    let volumeBbl = 0;

    if (sg > 0) {
      volumeBbl = totalWeight / (sg * 158.987);
    }

    const updatedProduct = await ConsumeProduct.findByIdAndUpdate(
      req.params.id,
      {
        ...req.body,
        final,
        cost,
        volumeBbl: +volumeBbl.toFixed(3)
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
