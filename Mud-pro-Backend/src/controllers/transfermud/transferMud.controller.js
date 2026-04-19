import Pit from "../../modules/pit/pit.model.js";
import TransferMud from "../../modules/transfermud/TransferMud.js";
import { getWritablePits } from "../../utils/pitReportState.js";
import { buildScopedFilter, readReportId } from "../../utils/reportScope.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));
const getWellId = (req) => String(req.params.wellId || "").trim();

const normalizeTransfers = (transfers = []) => {
  return transfers
    .map((item) => ({
      pitName: String(item.pitName || "").trim(),
      volume: round2(toNumber(item.volume)),
    }))
    .filter((item) => item.pitName && item.volume > 0);
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

const applyTransferToPits = async ({ wellId, reportId, from, transfers }) => {
  const cleanTransfers = normalizeTransfers(transfers);

  if (!wellId || !from || cleanTransfers.length === 0) {
    throw new Error("wellId, from, and valid transfers are required");
  }

  const totalTransferVol = round2(
    cleanTransfers.reduce((sum, item) => sum + item.volume, 0)
  );

  if (from === "Active System") {
    return {
      cleanTransfers,
      totalTransferVol,
      direction: "Active System to Storage",
    };
  }

  for (const item of cleanTransfers) {
    if (item.pitName !== "Active System") {
      throw new Error("When source is storage, destination must be 'Active System'");
    }
  }

  return {
    cleanTransfers,
    totalTransferVol,
    direction: "Storage to Active System",
  };
};

// CREATE ONE
export const createTransferMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const { from, transfers } = req.body;

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
    return res.status(500).json({
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
    const { entries } = req.body;

    if (!wellId || !Array.isArray(entries) || entries.length === 0) {
      return res.status(400).json({
        success: false,
        message: "wellId and entries are required",
      });
    }

    const created = [];

    for (const entry of entries) {
      const from = String(entry.from || "").trim();
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
    return res.status(500).json({
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

    const data = await TransferMud.find(
      buildScopedFilter(wellId, reportId)
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
    const { id } = req.params;

    const data = await TransferMud.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
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
    const { id } = req.params;
    const existing = await TransferMud.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Transfer Mud entry not found",
      });
    }

    const previousFrom = existing.from;
    const previousTransfers = existing.transfers;

    await revertTransferOnPits({
      wellId,
      reportId,
      from: previousFrom,
      transfers: previousTransfers,
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
      });
      cleanTransfers = applied.cleanTransfers;
      totalTransferVol = applied.totalTransferVol;
    } catch (error) {
      await applyTransferToPits({
        wellId,
        reportId,
        from: previousFrom,
        transfers: previousTransfers,
      });
      throw error;
    }

    existing.from = nextFrom;
    existing.transfers = cleanTransfers;
    existing.totalTransferVol = totalTransferVol;
    existing.reportId = reportId;
    await existing.save();

    return res.status(200).json({
      success: true,
      message: "Transfer Mud updated successfully",
      data: existing,
    });
  } catch (error) {
    return res.status(500).json({
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
    const { id } = req.params;

    const data = await TransferMud.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
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
      ...buildScopedFilter(wellId, reportId),
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
