import Pit from "../../modules/pit/pit.model.js";
import AddWater from "../../modules/addwater/AddWater.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));
const getWellId = (req) => String(req.params.wellId || "").trim();

const getAllPits = async (wellId) => {
  const pits = await Pit.find({ wellId }).sort({ createdAt: 1 });

  if (!pits.length) {
    throw new Error("No pits found for this wellId");
  }

  return pits;
};

const getActivePits = (allPits) => {
  const activePits = allPits.filter((pit) => pit.initialActive === true);

  if (!activePits.length) {
    throw new Error("No active pits found");
  }

  return activePits;
};

const addWaterToPit = async ({ wellId, to, volume }) => {
  const safeTo = String(to).trim();
  const waterVol = round2(toNumber(volume));
  const allPits = await getAllPits(wellId);

  if (safeTo === "Active System") {
    const activePits = getActivePits(allPits);

    let remaining = waterVol;

    for (let i = 0; i < activePits.length; i++) {
      const pit = activePits[i];
      const pitsLeft = activePits.length - i;
      const add = round2(remaining / pitsLeft);

      pit.volume = round2(toNumber(pit.volume) + add);
      remaining = round2(remaining - add);
      await pit.save();
    }
  } else {
    const targetPit = await Pit.findOne({
      wellId,
      pitName: safeTo,
    });

    if (!targetPit) {
      throw new Error(`Target pit '${to}' not found`);
    }

    targetPit.volume = round2(toNumber(targetPit.volume) + waterVol);
    await targetPit.save();
  }
};

const revertWaterFromPit = async ({ wellId, to, volume }) => {
  const safeTo = String(to).trim();
  const waterVol = round2(toNumber(volume));
  const allPits = await getAllPits(wellId);

  if (safeTo === "Active System") {
    const activePits = getActivePits(allPits);

    let remaining = waterVol;

    for (let i = 0; i < activePits.length; i++) {
      const pit = activePits[i];
      const pitsLeft = activePits.length - i;
      const deduct = round2(remaining / pitsLeft);

      pit.volume = round2(Math.max(0, toNumber(pit.volume) - deduct));
      remaining = round2(remaining - deduct);
      await pit.save();
    }
  } else {
    const targetPit = await Pit.findOne({
      wellId,
      pitName: safeTo,
    });

    if (!targetPit) {
      throw new Error(`Target pit '${to}' not found`);
    }

    targetPit.volume = round2(Math.max(0, toNumber(targetPit.volume) - waterVol));
    await targetPit.save();
  }
};

const prepareAddWaterData = (wellId, payload) => {
  const { to, volume } = payload;

  if (!wellId || !to || volume === undefined || volume === null) {
    throw new Error("wellId, to and volume are required");
  }

  const safeTo = String(to).trim();
  const waterVol = round2(toNumber(volume));

  if (waterVol <= 0) {
    throw new Error("Volume must be greater than 0");
  }

  return {
    wellId,
    to: safeTo,
    volume: waterVol,
  };
};

export const createAddWater = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const payloads = Array.isArray(req.body) ? req.body : [req.body];

    if (!payloads.length) {
      return res.status(400).json({
        success: false,
        message: "Request body is empty",
      });
    }

    const createdItems = [];

    for (const payload of payloads) {
      const prepared = prepareAddWaterData(wellId, payload);

      await addWaterToPit({
        wellId: prepared.wellId,
        to: prepared.to,
        volume: prepared.volume,
      });

      const item = await AddWater.create(prepared);
      createdItems.push(item);
    }

    return res.status(201).json({
      success: true,
      message:
        createdItems.length === 1
          ? "Add Water saved successfully"
          : "Multiple Add Water records saved successfully",
      count: createdItems.length,
      data: createdItems,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to save Add Water",
      error: error.message,
    });
  }
};

export const getAddWaterList = async (req, res) => {
  try {
    const wellId = getWellId(req);

    const items = await AddWater.find({ wellId }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: items.length,
      data: items,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Add Water records",
      error: error.message,
    });
  }
};

export const getAddWaterById = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;

    const item = await AddWater.findOne({ _id: id, wellId });

    if (!item) {
      return res.status(404).json({
        success: false,
        message: "Add Water record not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Add Water record",
      error: error.message,
    });
  }
};

export const updateAddWater = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;

    const existing = await AddWater.findOne({ _id: id, wellId });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Add Water record not found",
      });
    }

    await revertWaterFromPit({
      wellId,
      to: existing.to,
      volume: existing.volume,
    });

    const mergedPayload = {
      to: req.body.to ?? existing.to,
      volume: req.body.volume ?? existing.volume,
    };

    const prepared = prepareAddWaterData(wellId, mergedPayload);

    await addWaterToPit({
      wellId: prepared.wellId,
      to: prepared.to,
      volume: prepared.volume,
    });

    existing.to = prepared.to;
    existing.volume = prepared.volume;

    await existing.save();

    return res.status(200).json({
      success: true,
      message: "Add Water updated successfully",
      data: existing,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update Add Water",
      error: error.message,
    });
  }
};

export const deleteAddWater = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;

    const existing = await AddWater.findOne({ _id: id, wellId });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Add Water record not found",
      });
    }

    await revertWaterFromPit({
      wellId,
      to: existing.to,
      volume: existing.volume,
    });

    await AddWater.deleteOne({ _id: id, wellId });

    return res.status(200).json({
      success: true,
      message: "Add Water deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete Add Water",
      error: error.message,
    });
  }
};