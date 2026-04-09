import Pit from "../../modules/pit/pit.model.js";
import TransferMud from "../../modules/transfermud/TransferMud.js";

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

const addBackToActivePits = async ({ wellId, totalVolume }) => {
  if (totalVolume <= 0) return;

  const activePits = await Pit.find({
    wellId,
    initialActive: true,
  }).sort({ createdAt: 1 });

  if (!activePits.length) {
    throw new Error("No active pits found");
  }

  let remaining = round2(totalVolume);

  for (let i = 0; i < activePits.length; i++) {
    const pit = activePits[i];
    const pitsLeft = activePits.length - i;
    const add = round2(remaining / pitsLeft);

    pit.volume = round2(toNumber(pit.volume) + add);
    remaining = round2(remaining - add);
    await pit.save();
  }
};

const deductFromActivePits = async ({ wellId, totalVolume }) => {
  if (totalVolume <= 0) return;

  const activePits = await Pit.find({
    wellId,
    initialActive: true,
  }).sort({ createdAt: 1 });

  if (!activePits.length) {
    throw new Error("No active pits found");
  }

  const totalActiveVol = round2(
    activePits.reduce((sum, pit) => sum + toNumber(pit.volume), 0)
  );

  if (totalVolume > totalActiveVol) {
    throw new Error(
      `Transfer volume (${totalVolume}) exceeds active pits volume (${totalActiveVol})`
    );
  }

  let remaining = round2(totalVolume);

  for (let i = 0; i < activePits.length; i++) {
    const pit = activePits[i];
    if (remaining <= 0) break;

    const pitsLeft = activePits.length - i;
    let deduct = round2(remaining / pitsLeft);
    const currentVol = toNumber(pit.volume);

    if (deduct > currentVol) {
      deduct = round2(currentVol);
    }

    pit.volume = round2(currentVol - deduct);
    remaining = round2(remaining - deduct);
    await pit.save();
  }

  if (remaining > 0) {
    for (const pit of activePits) {
      if (remaining <= 0) break;

      const currentVol = toNumber(pit.volume);
      if (currentVol <= 0) continue;

      const deduct = Math.min(currentVol, remaining);
      pit.volume = round2(currentVol - deduct);
      remaining = round2(remaining - deduct);
      await pit.save();
    }
  }

  if (remaining > 0) {
    throw new Error("Unable to deduct full transfer volume from active pits");
  }
};

const revertTransferOnPits = async ({ wellId, from, transfers }) => {
  const cleanTransfers = normalizeTransfers(transfers);
  if (!wellId || !from || cleanTransfers.length === 0) return;

  const totalTransferVol = round2(
    cleanTransfers.reduce((sum, item) => sum + item.volume, 0)
  );

  const allPits = await Pit.find({ wellId }).sort({ createdAt: 1 });
  if (!allPits.length) {
    throw new Error("No pits found for this wellId");
  }

  const activePits = allPits.filter((pit) => pit.initialActive === true);
  const storagePits = allPits.filter((pit) => pit.initialActive === false);

  if (String(from).trim() === "Active System") {
    for (const item of cleanTransfers) {
      const targetPit = storagePits.find((pit) => pit.pitName === item.pitName);
      if (!targetPit) {
        throw new Error(`Storage pit '${item.pitName}' not found`);
      }

      const currentVol = toNumber(targetPit.volume);
      if (item.volume > currentVol) {
        throw new Error(
          `Cannot revert transfer. Storage pit '${item.pitName}' volume (${currentVol}) is less than transfer volume (${item.volume})`
        );
      }

      targetPit.volume = round2(currentVol - item.volume);
      await targetPit.save();
    }

    if (!activePits.length) {
      throw new Error("No active pits found");
    }

    await addBackToActivePits({
      wellId,
      totalVolume: totalTransferVol,
    });

    return;
  }

  const sourceStoragePit = storagePits.find((pit) => pit.pitName === String(from).trim());
  if (!sourceStoragePit) {
    throw new Error(`Source storage pit '${from}' not found`);
  }

  if (!activePits.length) {
    throw new Error("No active pits found");
  }

  await deductFromActivePits({
    wellId,
    totalVolume: totalTransferVol,
  });

  sourceStoragePit.volume = round2(
    toNumber(sourceStoragePit.volume) + totalTransferVol
  );
  await sourceStoragePit.save();
};

const applyTransferToPits = async ({ wellId, from, transfers }) => {
  const cleanTransfers = normalizeTransfers(transfers);

  if (!wellId || !from || cleanTransfers.length === 0) {
    throw new Error("wellId, from, and valid transfers are required");
  }

  const totalTransferVol = round2(
    cleanTransfers.reduce((sum, item) => sum + item.volume, 0)
  );

  const allPits = await Pit.find({ wellId }).sort({ createdAt: 1 });

  if (!allPits.length) {
    throw new Error("No pits found for this wellId");
  }

  const activePits = allPits.filter((pit) => pit.initialActive === true);
  const storagePits = allPits.filter((pit) => pit.initialActive === false);

  const totalActiveVol = round2(
    activePits.reduce((sum, pit) => sum + toNumber(pit.volume), 0)
  );

  if (from === "Active System") {
    if (!activePits.length) {
      throw new Error("No active pits found");
    }

    if (totalTransferVol > totalActiveVol) {
      throw new Error(
        `Transfer volume (${totalTransferVol}) exceeds active pits volume (${totalActiveVol})`
      );
    }

    for (const item of cleanTransfers) {
      const targetPit = storagePits.find((pit) => pit.pitName === item.pitName);

      if (!targetPit) {
        throw new Error(`Storage pit '${item.pitName}' not found`);
      }

      targetPit.volume = round2(toNumber(targetPit.volume) + item.volume);
      await targetPit.save();
    }

    let remainingToDeduct = totalTransferVol;

    for (let i = 0; i < activePits.length; i++) {
      const pit = activePits[i];
      if (remainingToDeduct <= 0) break;

      const pitsLeft = activePits.length - i;
      let deduct = round2(remainingToDeduct / pitsLeft);

      if (deduct > toNumber(pit.volume)) {
        deduct = round2(toNumber(pit.volume));
      }

      pit.volume = round2(toNumber(pit.volume) - deduct);
      remainingToDeduct = round2(remainingToDeduct - deduct);
      await pit.save();
    }

    if (remainingToDeduct > 0) {
      for (const pit of activePits) {
        if (remainingToDeduct <= 0) break;

        const available = toNumber(pit.volume);
        if (available <= 0) continue;

        const deduct = Math.min(available, remainingToDeduct);
        pit.volume = round2(available - deduct);
        remainingToDeduct = round2(remainingToDeduct - deduct);
        await pit.save();
      }
    }

    if (remainingToDeduct > 0) {
      throw new Error("Unable to deduct full transfer volume from active pits");
    }

    return {
      cleanTransfers,
      totalTransferVol,
      direction: "Active System to Storage",
    };
  }

  const sourceStoragePit = storagePits.find((pit) => pit.pitName === from);

  if (!sourceStoragePit) {
    throw new Error(`Source storage pit '${from}' not found`);
  }

  if (totalTransferVol > toNumber(sourceStoragePit.volume)) {
    throw new Error(
      `Transfer volume (${totalTransferVol}) exceeds source pit volume (${toNumber(sourceStoragePit.volume)})`
    );
  }

  for (const item of cleanTransfers) {
    if (item.pitName !== "Active System") {
      throw new Error("When source is storage, destination must be 'Active System'");
    }
  }

  if (!activePits.length) {
    throw new Error("No active pits found");
  }

  sourceStoragePit.volume = round2(toNumber(sourceStoragePit.volume) - totalTransferVol);
  await sourceStoragePit.save();

  let remainingToAdd = totalTransferVol;

  for (let i = 0; i < activePits.length; i++) {
    const pit = activePits[i];
    const pitsLeft = activePits.length - i;
    const add = round2(remainingToAdd / pitsLeft);

    pit.volume = round2(toNumber(pit.volume) + add);
    remainingToAdd = round2(remainingToAdd - add);
    await pit.save();
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
    const { from, transfers } = req.body;

    if (!wellId || !from || !Array.isArray(transfers) || transfers.length === 0) {
      return res.status(400).json({
        success: false,
        message: "wellId, from, and transfers are required",
      });
    }

    const { cleanTransfers, totalTransferVol } = await applyTransferToPits({
      wellId,
      from,
      transfers,
    });

    const item = await TransferMud.create({
      wellId,
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
        from,
        transfers,
      });

      const item = await TransferMud.create({
        wellId,
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

    const data = await TransferMud.find({ wellId }).sort({ createdAt: -1 });

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
    const { id } = req.params;

    const data = await TransferMud.findOne({ _id: id, wellId });

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
    const { id } = req.params;
    const existing = await TransferMud.findOne({ _id: id, wellId });

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
        from: nextFrom,
        transfers: nextTransfers,
      });
      cleanTransfers = applied.cleanTransfers;
      totalTransferVol = applied.totalTransferVol;
    } catch (error) {
      await applyTransferToPits({
        wellId,
        from: previousFrom,
        transfers: previousTransfers,
      });
      throw error;
    }

    existing.from = nextFrom;
    existing.transfers = cleanTransfers;
    existing.totalTransferVol = totalTransferVol;
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
    const { id } = req.params;

    const data = await TransferMud.findOne({ _id: id, wellId });

    if (!data) {
      return res.status(404).json({
        success: false,
        message: "Transfer Mud entry not found",
      });
    }

    await revertTransferOnPits({
      wellId,
      from: data.from,
      transfers: data.transfers,
    });

    await TransferMud.deleteOne({ _id: id, wellId });

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
