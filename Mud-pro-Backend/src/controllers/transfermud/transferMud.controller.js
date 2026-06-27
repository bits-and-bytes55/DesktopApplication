import TransferMud from "../../modules/transfermud/TransferMud.js";
import { buildScopedFilter, readReportId } from "../../utils/reportScope.js";
import { calculateTransferSourceBalanceForReport } from "../pitvolumename/volumeName.controller.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));
const getWellId = (req) => String(req.params.wellId || "").trim();
const readOperationInstanceKey = (req) =>
  String(req.query.operationInstanceKey ?? req.body?.operationInstanceKey ?? "").trim();

const operationInstanceFilter = (operationInstanceKey) => {
  if (!operationInstanceKey) return {};
  if (operationInstanceKey === "transferMud::legacy0") {
    return {
      $or: [
        { operationInstanceKey },
        { operationInstanceKey: { $exists: false } },
        { operationInstanceKey: null },
        { operationInstanceKey: "" },
      ],
    };
  }
  return { operationInstanceKey };
};

const normalizeTransfers = (transfers = []) => {
  return transfers
    .map((item) => ({
      pitName: String(item.pitName || "").trim(),
      volume: round2(toNumber(item.volume)),
    }))
    .filter((item) => item.pitName && item.volume > 0);
};

const transferEndVolEffect = (transfer) => {
  if (!transfer) return 0;
  const fromIsActiveSystem =
    String(transfer.from || "").trim().toLowerCase() === "active system";
  if (fromIsActiveSystem) {
    return -toNumber(transfer.totalTransferVol);
  }

  return normalizeTransfers(transfer.transfers).reduce(
    (sum, row) =>
      row.pitName.toLowerCase() === "active system"
        ? sum + row.volume
        : sum,
    0
  );
};

const validateSourceBalance = async ({
  wellId,
  reportId,
  from,
  totalTransferVol,
  existingTransfer = null,
}) => {
  const cleanFrom = String(from || "").trim();
  const fromIsActiveSystem = cleanFrom.toLowerCase() === "active system";
  let availableVolume = await calculateTransferSourceBalanceForReport({
    wellId,
    reportId,
    source: cleanFrom,
    excludeTransferId: fromIsActiveSystem ? "" : existingTransfer?._id,
  });

  if (fromIsActiveSystem && existingTransfer) {
    availableVolume = round2(
      availableVolume - transferEndVolEffect(existingTransfer)
    );
  }

  availableVolume = Math.max(0, round2(availableVolume));
  if (totalTransferVol > availableVolume + 0.005) {
    const error = new Error(
      `Transfer volume ${totalTransferVol.toFixed(2)} bbl exceeds available ` +
        `${cleanFrom} volume ${availableVolume.toFixed(2)} bbl`
    );
    error.statusCode = 400;
    throw error;
  }
};

const addBackToActivePits = async ({ wellId, reportId, totalVolume }) => {
  return;
};

const deductFromActivePits = async ({ wellId, reportId, totalVolume }) => {
  return;
};

const revertTransferOnPits = async ({ wellId, reportId, from, transfers }) => {
  return;
};

const applyTransferToPits = async ({
  wellId,
  reportId,
  from,
  transfers,
  existingTransfer = null,
}) => {
  const cleanTransfers = normalizeTransfers(transfers);

  if (!wellId || !from || cleanTransfers.length === 0) {
    throw new Error("wellId, from, and valid transfers are required");
  }

  const totalTransferVol = round2(
    cleanTransfers.reduce((sum, item) => sum + item.volume, 0)
  );

  const cleanFrom = String(from).trim();
  const fromIsActiveSystem = cleanFrom.toLowerCase() === "active system";

  for (const item of cleanTransfers) {
    if (item.pitName.toLowerCase() === cleanFrom.toLowerCase()) {
      throw new Error("Source and destination cannot be the same");
    }
  }

  await validateSourceBalance({
    wellId,
    reportId,
    from: cleanFrom,
    totalTransferVol,
    existingTransfer,
  });

  if (fromIsActiveSystem) {
    return {
      cleanTransfers,
      totalTransferVol,
      direction: "Active System to Storage",
    };
  }

  return {
    cleanTransfers,
    totalTransferVol,
    direction: "Storage Transfer",
  };
};

// CREATE ONE
export const createTransferMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const operationInstanceKey = readOperationInstanceKey(req);
    const { from, transfers } = req.body;

    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required for Transfer Mud",
      });
    }

    if (!wellId || !from || !Array.isArray(transfers) || transfers.length === 0) {
      return res.status(400).json({
        success: false,
        message: "wellId, from, and transfers are required",
      });
    }

    const { cleanTransfers, totalTransferVol } = await applyTransferToPits({
      wellId,
      reportId,
      from,
      transfers,
    });

    const item = await TransferMud.create({
      wellId,
      reportId,
      operationInstanceKey,
      from: String(from).trim(),
      transfers: cleanTransfers,
      totalTransferVol,
    });

    return res.status(201).json({
      success: true,
      message: "Transfer Mud created successfully",
      data: item,
    });
  } catch (error) {
    return res.status(error.statusCode || 500).json({
      success: false,
      message: "Transfer mud failed",
      error: error.message,
    });
  }
};

// CREATE MANY
export const createManyTransferMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const requestOperationInstanceKey = readOperationInstanceKey(req);
    const { entries } = req.body;

    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required for Transfer Mud",
      });
    }

    if (!wellId || !Array.isArray(entries) || entries.length === 0) {
      return res.status(400).json({
        success: false,
        message: "wellId and entries are required",
      });
    }

    const created = [];

    for (const entry of entries) {
      const from = String(entry.from || "").trim();
      const operationInstanceKey = String(
        entry.operationInstanceKey || requestOperationInstanceKey || ""
      ).trim();
      const transfers = Array.isArray(entry.transfers) ? entry.transfers : [];

      const { cleanTransfers, totalTransferVol } = await applyTransferToPits({
        wellId,
        reportId,
        from,
        transfers,
      });

      const item = await TransferMud.create({
        wellId,
        reportId,
        operationInstanceKey,
        from,
        transfers: cleanTransfers,
        totalTransferVol,
      });

      created.push(item);
    }

    return res.status(201).json({
      success: true,
      message: "Multiple Transfer Mud entries created successfully",
      count: created.length,
      data: created,
    });
  } catch (error) {
    return res.status(error.statusCode || 500).json({
      success: false,
      message: "Bulk transfer mud failed",
      error: error.message,
    });
  }
};

// GET ALL BY WELL
export const getTransferMudByWell = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const operationInstanceKey = readOperationInstanceKey(req);

    if (!reportId) {
      return res.status(200).json({
        success: true,
        count: 0,
        data: [],
      });
    }

    const data = await TransferMud.find(
      buildScopedFilter(
        wellId,
        reportId,
        operationInstanceFilter(operationInstanceKey)
      )
    ).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Transfer Mud entries",
      error: error.message,
    });
  }
};

// GET SINGLE
export const getTransferMudById = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const operationInstanceKey = readOperationInstanceKey(req);
    const { id } = req.params;

    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required for Transfer Mud",
      });
    }

    const data = await TransferMud.findOne({
      _id: id,
      ...buildScopedFilter(
        wellId,
        reportId,
        operationInstanceFilter(operationInstanceKey)
      ),
    });

    if (!data) {
      return res.status(404).json({
        success: false,
        message: "Transfer Mud entry not found",
      });
    }

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Transfer Mud entry",
      error: error.message,
    });
  }
};

// UPDATE RECORD ONLY
export const updateTransferMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const operationInstanceKey = readOperationInstanceKey(req);
    const { id } = req.params;

    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required for Transfer Mud",
      });
    }

    const existing = await TransferMud.findOne({
      _id: id,
      ...buildScopedFilter(
        wellId,
        reportId,
        operationInstanceFilter(operationInstanceKey)
      ),
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Transfer Mud entry not found",
      });
    }

    await revertTransferOnPits({
      wellId,
      reportId,
      from: existing.from,
      transfers: existing.transfers,
    });

    const nextFrom =
      req.body.from !== undefined ? String(req.body.from).trim() : existing.from;
    const nextTransfers =
      req.body.transfers !== undefined ? req.body.transfers : existing.transfers;

    let cleanTransfers;
    let totalTransferVol;
    try {
      const applied = await applyTransferToPits({
        wellId,
        reportId,
        from: nextFrom,
        transfers: nextTransfers,
        existingTransfer: existing,
      });
      cleanTransfers = applied.cleanTransfers;
      totalTransferVol = applied.totalTransferVol;
    } catch (error) {
      throw error;
    }

    existing.from = nextFrom;
    existing.transfers = cleanTransfers;
    existing.totalTransferVol = totalTransferVol;
    existing.reportId = reportId;
    if (operationInstanceKey) {
      existing.operationInstanceKey = operationInstanceKey;
    }
    await existing.save();

    return res.status(200).json({
      success: true,
      message: "Transfer Mud updated successfully",
      data: existing,
    });
  } catch (error) {
    return res.status(error.statusCode || 500).json({
      success: false,
      message: "Failed to update Transfer Mud entry",
      error: error.message,
    });
  }
};

// DELETE
export const deleteTransferMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const operationInstanceKey = readOperationInstanceKey(req);
    const { id } = req.params;

    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required for Transfer Mud",
      });
    }

    const data = await TransferMud.findOne({
      _id: id,
      ...buildScopedFilter(
        wellId,
        reportId,
        operationInstanceFilter(operationInstanceKey)
      ),
    });

    if (!data) {
      return res.status(404).json({
        success: false,
        message: "Transfer Mud entry not found",
      });
    }

    await revertTransferOnPits({
      wellId,
      reportId,
      from: data.from,
      transfers: data.transfers,
    });

    await TransferMud.deleteOne({
      _id: id,
      ...buildScopedFilter(
        wellId,
        reportId,
        operationInstanceFilter(operationInstanceKey)
      ),
    });

    return res.status(200).json({
      success: true,
      message: "Transfer Mud deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete Transfer Mud entry",
      error: error.message,
    });
  }
};
