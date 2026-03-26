import Service from "../../../modules/ConsumeServices/Services/Service.js";

/**
 * @desc    Create Service (With Auto Cost Calculation)
 */
export const createService = async (req, res) => {
  try {
    let {
      usage = 0,
      price = 0,
    } = req.body;

    // 🔥 Auto Costa Calculation
    const cost = Number(usage) * Number(price);

    const newService = await Service.create({
      ...req.body,
      cost,
    });

    res.status(201).json({
      success: true,
      message: "Service created successfully",
      data: newService,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Get All Services
 */
export const getAllServices = async (req, res) => {
  try {
    const services = await Service.find();

    res.status(200).json({
      success: true,
      count: services.length,
      data: services,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Get Single Service
 */
export const getServiceById = async (req, res) => {
  try {
    const service = await Service.findById(req.params.id);

    if (!service) {
      return res.status(404).json({
        success: false,
        message: "Service not found",
      });
    }

    res.status(200).json({
      success: true,
      data: service,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Update Service (With Recalculation)
 */
export const updateService = async (req, res) => {
  try {
    const existing = await Service.findById(req.params.id);

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Service not found",
      });
    }

    const usage = Number(req.body.usage ?? existing.usage ?? 0);
    const price = Number(req.body.price ?? existing.price ?? 0);

    // 🔥 Recalculate
    const cost = usage * price;

    const updatedService = await Service.findByIdAndUpdate(
      req.params.id,
      {
        ...req.body,
        cost,
      },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Service updated successfully",
      data: updatedService,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Delete Service
 */
export const deleteService = async (req, res) => {
  try {
    const service = await Service.findByIdAndDelete(req.params.id);

    if (!service) {
      return res.status(404).json({
        success: false,
        message: "Service not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Service deleted successfully",
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
