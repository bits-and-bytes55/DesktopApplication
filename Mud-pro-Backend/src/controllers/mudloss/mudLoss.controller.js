import Pit from "../../modules/pit/pit.model.js";
import MudLoss from "../../modules/mudloss/MudLoss.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));
const getWellId = (req) => String(req.params.wellId || "").trim();

const deductFromActivePits = async ({ wellId, totalLoss }) => {
  const allPits = await Pit.find({ wellId }).sort({ createdAt: 1 });
  const activePits = allPits.filter((pit) => pit.initialActive === true);

  if (!activePits.length) {
    throw new Error("No active pits found for this wellId");
  }

  const totalActiveVol = activePits.reduce((sum, pit) => sum + toNumber(pit.volume), 0);
  if (totalLoss > totalActiveVol) {
    throw new Error(`Mud loss (${totalLoss}) exceeds active pits volume (${totalActiveVol})`);
  }

  let remaining = round2(totalLoss);

  for (let i = 0; i < activePits.length; i++) {
    const pit = activePits[i];
    const pitsLeft = activePits.length - i;
    const deduct = round2(remaining / pitsLeft);

    const currentPitVol = toNumber(pit.volume);
    const actualDeduct = Math.min(currentPitVol, deduct);

    pit.volume = round2(Math.max(0, currentVol - actualDeduct));
    
    remaining = round2(remaining - actualDeduct);
    await pit.save();
  }

  // If there's still remaining due to rounding or Math.min, deduct from first available active pit
  if (remaining > 0) {
      for (const pit of activePits) {
          if (remaining <= 0) break;
          const vol = toNumber(pit.volume);
          if (vol > 0) {
              const take = Math.min(vol, remaining);
              pit.volume = round2(vol - take);
              remaining = round2(remaining - take);
              await pit.save();
          }
      }
  }
};

const revertToActivePits = async ({ wellId, totalLoss }) => {
  if (totalLoss <= 0) return;

  const allPits = await Pit.find({ wellId }).sort({ createdAt: 1 });
  const activePits = allPits.filter((pit) => pit.initialActive === true);

  if (!activePits.length) return;

  let remaining = round2(totalLoss);
  for (let i = 0; i < activePits.length; i++) {
    const pit = activePits[i];
    const pitsLeft = activePits.length - i;
    const add = round2(remaining / pitsLeft);

    pit.volume = round2(toNumber(pit.volume) + add);
    remaining = round2(remaining - add);
    await pit.save();
  }
};

export const createMudLoss = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const {
      cuttingsRetention,
      seepage,
      dump,
      shakers,
      centrifuge,
      evaporation,
      pitCleaning,
      formation,
      abandonInHole,
      leftBehindCasing,
      tripping,
    } = req.body;

    const totalLoss = round2(
      toNumber(cuttingsRetention) +
        toNumber(seepage) +
        toNumber(dump) +
        toNumber(shakers) +
        toNumber(centrifuge) +
        toNumber(evaporation) +
        toNumber(pitCleaning) +
        toNumber(formation) +
        toNumber(abandonInHole) +
        toNumber(leftBehindCasing) +
        toNumber(tripping)
    );

    if (totalLoss <= 0) {
      return res.status(400).json({
        success: false,
        message: "Total mud loss must be greater than 0",
      });
    }

    await deductFromActivePits({ wellId, totalLoss });

    const item = await MudLoss.create({
      wellId,
      cuttingsRetention: toNumber(cuttingsRetention),
      seepage: toNumber(seepage),
      dump: toNumber(dump),
      shakers: toNumber(shakers),
      centrifuge: toNumber(centrifuge),
      evaporation: toNumber(evaporation),
      pitCleaning: toNumber(pitCleaning),
      formation: toNumber(formation),
      abandonInHole: toNumber(abandonInHole),
      leftBehindCasing: toNumber(leftBehindCasing),
      tripping: toNumber(tripping),
      totalLoss,
    });

    return res.status(201).json({
      success: true,
      message: "Mud Loss record saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to save Mud Loss",
      error: error.message,
    });
  }
};

export const getMudLossList = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const items = await MudLoss.find({ wellId }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: items.length,
      data: items,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Mud Loss records",
      error: error.message,
    });
  }
};

export const getMudLossById = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;

    const item = await MudLoss.findOne({ _id: id, wellId });

    if (!item) {
      return res.status(404).json({
        success: false,
        message: "Mud Loss record not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Mud Loss record",
      error: error.message,
    });
  }
};

export const updateMudLoss = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;

    const existing = await MudLoss.findOne({ _id: id, wellId });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Mud Loss record not found",
      });
    }

    // Revert old volume
    await revertToActivePits({ wellId, totalLoss: toNumber(existing.totalLoss) });

    const updatedData = {
      cuttingsRetention: req.body.cuttingsRetention ?? existing.cuttingsRetention,
      seepage: req.body.seepage ?? existing.seepage,
      dump: req.body.dump ?? existing.dump,
      shakers: req.body.shakers ?? existing.shakers,
      centrifuge: req.body.centrifuge ?? existing.centrifuge,
      evaporation: req.body.evaporation ?? existing.evaporation,
      pitCleaning: req.body.pitCleaning ?? existing.pitCleaning,
      formation: req.body.formation ?? existing.formation,
      abandonInHole: req.body.abandonInHole ?? existing.abandonInHole,
      leftBehindCasing: req.body.leftBehindCasing ?? existing.leftBehindCasing,
      tripping: req.body.tripping ?? existing.tripping,
    };

    const totalLoss = round2(
      toNumber(updatedData.cuttingsRetention) +
        toNumber(updatedData.seepage) +
        toNumber(updatedData.dump) +
        toNumber(updatedData.shakers) +
        toNumber(updatedData.centrifuge) +
        toNumber(updatedData.evaporation) +
        toNumber(updatedData.pitCleaning) +
        toNumber(updatedData.formation) +
        toNumber(updatedData.abandonInHole) +
        toNumber(updatedData.leftBehindCasing) +
        toNumber(updatedData.tripping)
    );

    await deductFromActivePits({ wellId, totalLoss });

    existing.set({ ...updatedData, totalLoss });
    await existing.save();

    return res.status(200).json({
      success: true,
      message: "Mud Loss record updated successfully",
      data: existing,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update Mud Loss",
      error: error.message,
    });
  }
};

export const deleteMudLoss = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;

    const existing = await MudLoss.findOne({ _id: id, wellId });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Mud Loss record not found",
      });
    }

    await revertToActivePits({ wellId, totalLoss: toNumber(existing.totalLoss) });

    await MudLoss.deleteOne({ _id: id, wellId });

    return res.status(200).json({
      success: true,
      message: "Mud Loss record deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete Mud Loss",
      error: error.message,
    });
  }
};