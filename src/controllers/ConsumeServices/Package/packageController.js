import Package from "../../../modules/ConsumeServices/Package/Package.js";

/**
 * @desc    Create Package (With Auto Calculation)
 */
export const createPackage = async (req, res) => {
  try {
    let {
      initial = 0,
      used = 0,
      price = 0,
    } = req.body;

    // 🔥 Auto Calculation
    const final = Number(initial) - Number(used);
    const cost = Number(used) * Number(price);

    const newPackage = await Package.create({
      ...req.body,
      final,
      cost,
    });

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


/**
 * @desc    Get All Packages
 */
export const getAllPackages = async (req, res) => {
  try {
    const packages = await Package.find();

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
 * @desc    Get Single Package
 */
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


/**
 * @desc    Update Package (With Recalculation)
 */
export const updatePackage = async (req, res) => {
  try {
    const existing = await Package.findById(req.params.id);

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Package not found",
      });
    }

    const initial = Number(req.body.initial ?? existing.initial ?? 0);
    const used = Number(req.body.used ?? existing.used ?? 0);
    const price = Number(req.body.price ?? existing.price ?? 0);

    // 🔥 Recalculate
    const final = initial - used;
    const cost = used * price;

    const updatedPackage = await Package.findByIdAndUpdate(
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


/**
 * @desc    Delete Package
 */
export const deletePackage = async (req, res) => {
  try {
    const pkg = await Package.findByIdAndDelete(req.params.id);

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
