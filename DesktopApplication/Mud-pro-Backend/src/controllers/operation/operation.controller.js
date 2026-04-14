import Operation from "../../modules/operation/operation.model.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
};

// CREATE
export const createOperation = async (req, res) => {
  try {
    const { description, isActive, sortOrder } = req.body;

    if (!description || !String(description).trim()) {
      return res.status(400).json({
        success: false,
        message: "description is required",
      });
    }

    const safeDescription = String(description).trim();

    const existing = await Operation.findOne({
      description: { $regex: `^${safeDescription}$`, $options: "i" },
    });

    if (existing) {
      return res.status(400).json({
        success: false,
        message: "Operation already exists",
      });
    }

    const item = await Operation.create({
      description: safeDescription,
      isActive: isActive !== undefined ? isActive : true,
      sortOrder: toNumber(sortOrder),
    });

    return res.status(201).json({
      success: true,
      message: "Operation created successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to create operation",
      error: error.message,
    });
  }
};

// GET ALL
export const getAllOperations = async (req, res) => {
  try {
    const { activeOnly } = req.query;

    const filter = {};

    if (activeOnly === "true") {
      filter.isActive = true;
    }

    const items = await Operation.find(filter).sort({
      sortOrder: 1,
      createdAt: 1,
    });

    return res.status(200).json({
      success: true,
      count: items.length,
      data: items,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch operations",
      error: error.message,
    });
  }
};

// GET BY ID
export const getOperationById = async (req, res) => {
  try {
    const { id } = req.params;

    const item = await Operation.findById(id);

    if (!item) {
      return res.status(404).json({
        success: false,
        message: "Operation not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch operation",
      error: error.message,
    });
  }
};

// UPDATE
export const updateOperation = async (req, res) => {
  try {
    const { id } = req.params;
    const { description, isActive, sortOrder } = req.body;

    const existing = await Operation.findById(id);

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Operation not found",
      });
    }

    if (description !== undefined) {
      const safeDescription = String(description).trim();

      if (!safeDescription) {
        return res.status(400).json({
          success: false,
          message: "description cannot be empty",
        });
      }

      const duplicate = await Operation.findOne({
        _id: { $ne: id },
        description: { $regex: `^${safeDescription}$`, $options: "i" },
      });

      if (duplicate) {
        return res.status(400).json({
          success: false,
          message: "Another operation with same description already exists",
        });
      }

      existing.description = safeDescription;
    }

    if (isActive !== undefined) {
      existing.isActive = isActive;
    }

    if (sortOrder !== undefined) {
      existing.sortOrder = toNumber(sortOrder);
    }

    await existing.save();

    return res.status(200).json({
      success: true,
      message: "Operation updated successfully",
      data: existing,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update operation",
      error: error.message,
    });
  }
};

// DELETE
export const deleteOperation = async (req, res) => {
  try {
    const { id } = req.params;

    const existing = await Operation.findById(id);

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Operation not found",
      });
    }

    await Operation.findByIdAndDelete(id);

    return res.status(200).json({
      success: true,
      message: "Operation deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete operation",
      error: error.message,
    });
  }
};