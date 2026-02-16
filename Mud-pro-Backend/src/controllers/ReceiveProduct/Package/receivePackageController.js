import ReceivePackage from "../../../modules/ReceiveProduct/Package/ReceivePackage.js";

/**
 * @desc    Create Receive Package
 */
export const createReceivePackage = async (req, res) => {
  try {
    const newPackage = await ReceivePackage.create({
      ...req.body,
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
    const packages = await ReceivePackage.find();

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
    const updatedPackage = await ReceivePackage.findByIdAndUpdate(
      req.params.id,
      {
        ...req.body,
      },
      { new: true }
    );

    if (!updatedPackage) {
      return res.status(404).json({
        success: false,
        message: "Receive Package not found",
      });
    }

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
