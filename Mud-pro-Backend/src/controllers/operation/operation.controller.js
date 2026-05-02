import Operation from "../../modules/operation/operation.model.js";
import ConsumeProduct from "../../modules/Consumeproduct/ConsumeProduct.js";
import ConsumeProductDistributionState from "../../modules/Consumeproduct/ConsumeProductDistributionState.js";
import ConsumePackage from "../../modules/ConsumeServices/Package/Package.js";
import Service from "../../modules/ConsumeServices/Services/Service.js";
import Engineering from "../../modules/ConsumeServices/Engineers/Engineering.js";
import ReceiveProduct from "../../modules/ReceiveProduct/Product/ReceiveProduct.js";
import ReceivePackage from "../../modules/ReceiveProduct/Package/ReceivePackage.js";
import ReturnProduct from "../../modules/ReturnProduct/Product/ReturnProduct.js";
import ReturnPackage from "../../modules/ReturnProduct/Package/ReturnPackage.js";
import TransferMud from "../../modules/transfermud/TransferMud.js";
import ReceiveMud from "../../modules/receivemud/ReceiveMud.js";
import ReturnLostMud from "../../modules/returnlostmud/ReturnLostMud.js";
import AddWater from "../../modules/addwater/AddWater.js";
import OtherVolAddition from "../../modules/othervol/OtherVolAddition.js";
import MudLoss from "../../modules/mudloss/MudLoss.js";
import MudLossStorage from "../../modules/mudlossstorage/MudLossStorage.js";
import EmptyFluidActiveSystem from "../../modules/emptyfluidactivesystem/EmptyFluidActiveSystem.js";
import { legacyReportScope } from "../../utils/reportScope.js";

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

export const deleteOperationData = async (req, res) => {
  try {
    const wellId = String(req.params.wellId ?? "").trim();
    const operationType = String(req.params.operationType ?? "").trim();
    const reportId = String(req.query.reportId ?? req.body?.reportId ?? "").trim();

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required",
      });
    }

    if (!Object.prototype.hasOwnProperty.call(operationDataModels, operationType)) {
      return res.status(400).json({
        success: false,
        message: "Unknown operation type",
      });
    }

    const models = operationDataModels[operationType];
    const filter = buildOperationDataFilter(wellId, reportId);
    const results = await Promise.all(
      models.map(async (Model) => {
        const result = await Model.deleteMany(filter);
        return {
          model: Model.modelName,
          deletedCount: result.deletedCount || 0,
        };
      })
    );

    const deletedCount = results.reduce(
      (sum, item) => sum + item.deletedCount,
      0
    );

    return res.status(200).json({
      success: true,
      message:
        deletedCount > 0
          ? "Operation data deleted successfully"
          : "Operation removed. No saved data found for this operation.",
      operationType,
      deletedCount,
      details: results,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete operation data",
      error: error.message,
    });
  }
};

const operationDataModels = {
  consumeServices: [ConsumePackage, Service, Engineering],
  consumeProduct: [ConsumeProduct, ConsumeProductDistributionState],
  receiveProduct: [ReceiveProduct, ReceivePackage],
  returnProduct: [ReturnProduct, ReturnPackage],
  transferMud: [TransferMud],
  receiveMud: [ReceiveMud],
  returnLostMud: [ReturnLostMud],
  addWater: [AddWater],
  switchPit: [],
  switchMudType: [],
  emptyActiveSystem: [EmptyFluidActiveSystem],
  otherVolAddition: [OtherVolAddition],
  mudLossActiveSystem: [MudLoss],
  mudLossStorage: [MudLossStorage],
};

const buildOperationDataFilter = (wellId, reportId) => {
  const cleanWellId = String(wellId ?? "").trim();
  const cleanReportId = String(reportId ?? "").trim();

  if (!cleanReportId) {
    return {
      wellId: cleanWellId,
      ...legacyReportScope(),
    };
  }

  return {
    wellId: cleanWellId,
    reportId: cleanReportId,
  };
};
