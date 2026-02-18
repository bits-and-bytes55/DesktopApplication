import UgInventorySnapshot from "../../modules/ugInventory/ugInventoryProductModel.js";

// ─────────────────────────────────────────────────────────────────
// GET  /api/ug-inventory/:wellId
// Returns the latest snapshot for a well (or empty defaults)
// ─────────────────────────────────────────────────────────────────
export const getUgInventory = async (req, res) => {
  try {
    const { wellId } = req.params;

    const snapshot = await UgInventorySnapshot.findOne({ wellId }).sort({
      updatedAt: -1,
    });

    if (!snapshot) {
      // Return empty structure so Flutter can render an empty table
      return res.status(200).json({
        success: true,
        data: {
          products: [],
          premixed: [],
          obm: [],
          bulkTankSetupFee: "",
          taxRate: "",
          applyPricesOption: "To All",
          fromDate: "",
        },
      });
    }

    res.status(200).json({ success: true, data: snapshot });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─────────────────────────────────────────────────────────────────
// POST  /api/ug-inventory/:wellId
// Upsert (create or replace) the full snapshot for a well
// ─────────────────────────────────────────────────────────────────
export const saveUgInventory = async (req, res) => {
  try {
    const { wellId } = req.params;
    const {
      products,
      premixed,
      obm,
      bulkTankSetupFee,
      taxRate,
      applyPricesOption,
      fromDate,
    } = req.body;

    const snapshot = await UgInventorySnapshot.findOneAndUpdate(
      { wellId },
      {
        $set: {
          products:          products          ?? [],
          premixed:          premixed          ?? [],
          obm:               obm               ?? [],
          bulkTankSetupFee:  bulkTankSetupFee  ?? "",
          taxRate:           taxRate           ?? "",
          applyPricesOption: applyPricesOption ?? "To All",
          fromDate:          fromDate          ?? "",
        },
      },
      { new: true, upsert: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      message: "Inventory saved successfully",
      data: snapshot,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};