import Engineering from "../../../modules/ConsumeServices/Engineers/Engineering.js";

/**
 * @desc    Create Engineering (With Auto Cost Calculation)
 */
export const createEngineering = async (req, res) => {
  try {
    let {
      usage = 0,
      price = 0,
    } = req.body;

    // 🔥 Auto Cost Calculation
    const cost = Number(usage) * Number(price);

    const newEngineering = await Engineering.create({
      ...req.body,
      cost,
    });

    res.status(201).json({
      success: true,
      message: "Engineering created successfully",
      data: newEngineering,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Get All Engineering Records
 */
export const getAllEngineering = async (req, res) => {
  try {
    const records = await Engineering.find();

    res.status(200).json({
      success: true,
      count: records.length,
      data: records,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Get Single Engineering Record
 */
export const getEngineeringById = async (req, res) => {
  try {
    const record = await Engineering.findById(req.params.id);

    if (!record) {
      return res.status(404).json({
        success: false,
        message: "Engineering record not found",
      });
    }

    res.status(200).json({
      success: true,
      data: record,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Update Engineering (With Recalculation)
 */
export const updateEngineering = async (req, res) => {
  try {
    const existing = await Engineering.findById(req.params.id);

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Engineering record not found",
      });
    }

    const usage = Number(req.body.usage ?? existing.usage ?? 0);
    const price = Number(req.body.price ?? existing.price ?? 0);

    // 🔥 Recalculate
    const cost = usage * price;

    const updatedRecord = await Engineering.findByIdAndUpdate(
      req.params.id,
      {
        ...req.body,
        cost,
      },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Engineering updated successfully",
      data: updatedRecord,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


/**
 * @desc    Delete Engineering
 */
export const deleteEngineering = async (req, res) => {
  try {
    const record = await Engineering.findByIdAndDelete(req.params.id);

    if (!record) {
      return res.status(404).json({
        success: false,
        message: "Engineering record not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Engineering deleted successfully",
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
