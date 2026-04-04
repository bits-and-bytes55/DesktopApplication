import Pit from "../../modules/pit/pit.model.js";
import Premixed from "../../modules/inventory/premixed.model.js";
import ReceiveMud from "../../modules/receivemud/ReceiveMud.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));
const getWellId = (req) => String(req.params.wellId || "").trim();

const findPremixedMud = async (wellId, premixedMud) => {
  return await Premixed.findOne({
    wellId,
    description: { $regex: `^${String(premixedMud).trim()}$`, $options: "i" },
  });
};

const applyVolumeToPit = async ({ wellId, to, netVolume, mw, mudType }) => {
  const allPits = await Pit.find({ wellId }).sort({ createdAt: 1 });

  if (!allPits.length) {
    throw new Error("No pits found for this wellId");
  }

  if (String(to).trim() === "Active System") {
    const activePits = allPits.filter((pit) => pit.initialActive === true);

    if (!activePits.length) {
      throw new Error("No active pits found");
    }

    let remaining = round2(netVolume);

    for (let i = 0; i < activePits.length; i++) {
      const pit = activePits[i];
      const pitsLeft = activePits.length - i;
      const add = round2(remaining / pitsLeft);

      pit.volume = round2(toNumber(pit.volume) + add);
      pit.density = mw;
      pit.fluidType = mudType;

      remaining = round2(remaining - add);
      await pit.save();
    }
  } else {
    const targetPit = await Pit.findOne({
      wellId,
      pitName: String(to).trim(),
    });

    if (!targetPit) {
      throw new Error(`Target pit '${to}' not found`);
    }

    targetPit.volume = round2(toNumber(targetPit.volume) + netVolume);
    targetPit.density = mw;
    targetPit.fluidType = mudType;

    await targetPit.save();
  }
};

const revertVolumeFromPit = async ({ wellId, to, netVolume }) => {
  const allPits = await Pit.find({ wellId }).sort({ createdAt: 1 });

  if (!allPits.length) {
    throw new Error("No pits found for this wellId");
  }

  if (String(to).trim() === "Active System") {
    const activePits = allPits.filter((pit) => pit.initialActive === true);

    if (!activePits.length) {
      throw new Error("No active pits found");
    }

    let remaining = round2(netVolume);

    for (let i = 0; i < activePits.length; i++) {
      const pit = activePits[i];
      const pitsLeft = activePits.length - i;
      const minus = round2(remaining / pitsLeft);

      const currentVolume = toNumber(pit.volume);
      pit.volume = round2(Math.max(0, currentVolume - minus));

      remaining = round2(remaining - minus);
      await pit.save();
    }
  } else {
    const targetPit = await Pit.findOne({
      wellId,
      pitName: String(to).trim(),
    });

    if (!targetPit) {
      throw new Error(`Target pit '${to}' not found`);
    }

    const currentVolume = toNumber(targetPit.volume);
    targetPit.volume = round2(Math.max(0, currentVolume - netVolume));

    await targetPit.save();
  }
};

const prepareReceiveMudData = async (wellId, payload) => {
  const {
    bolNo,
    premixedMud,
    mw,
    mudType,
    leasingFee,
    from,
    to,
    volume,
    leased,
    lossVolume,
  } = payload;

  if (!wellId || !premixedMud || !to || volume === undefined || volume === null) {
    throw new Error("wellId, premixedMud, to and volume are required");
  }

  const grossVolume = round2(toNumber(volume));
  const loss = round2(toNumber(lossVolume));
  const netVolume = round2(grossVolume - loss);

  if (grossVolume < 0) {
    throw new Error("Volume cannot be negative");
  }

  if (loss < 0 || loss > grossVolume) {
    throw new Error("Loss Volume must be between 0 and volume");
  }

  const premixed = await findPremixedMud(wellId, premixedMud);

  if (!premixed) {
    throw new Error(`Premixed mud '${premixedMud}' not found for this well`);
  }

  const finalMw =
    mw !== undefined && mw !== null && mw !== ""
      ? round2(toNumber(mw))
      : round2(toNumber(premixed.mw));

  const finalMudType =
    mudType !== undefined && mudType !== null && mudType !== ""
      ? mudType
      : premixed.mudType || "";

  const finalLeasingFee =
    leasingFee !== undefined && leasingFee !== null && leasingFee !== ""
      ? round2(toNumber(leasingFee))
      : round2(toNumber(premixed.leasingFee));

  return {
    wellId,
    bolNo: bolNo || "",
    premixedMud: String(premixedMud).trim(),
    mw: finalMw,
    mudType: finalMudType,
    leasingFee: finalLeasingFee,
    from: from || "",
    to: String(to).trim(),
    volume: grossVolume,
    leased: leased === true || leased === "true",
    lossVolume: loss,
    netVolume,
  };
};

export const createReceiveMud = async (req, res) => {
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
      const prepared = await prepareReceiveMudData(wellId, payload);

      await applyVolumeToPit({
        wellId,
        to: prepared.to,
        netVolume: prepared.netVolume,
        mw: prepared.mw,
        mudType: prepared.mudType,
      });

      const item = await ReceiveMud.create(prepared);
      createdItems.push(item);
    }

    return res.status(201).json({
      success: true,
      message:
        createdItems.length === 1
          ? "Receive Mud saved successfully"
          : "Multiple Receive Mud records saved successfully",
      count: createdItems.length,
      data: createdItems,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to save Receive Mud",
      error: error.message,
    });
  }
};

export const getReceiveMudList = async (req, res) => {
  try {
    const wellId = getWellId(req);

    const items = await ReceiveMud.find({ wellId }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: items.length,
      data: items,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Receive Mud records",
      error: error.message,
    });
  }
};

export const getReceiveMudById = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;

    const item = await ReceiveMud.findOne({ _id: id, wellId });

    if (!item) {
      return res.status(404).json({
        success: false,
        message: "Receive Mud record not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Receive Mud record",
      error: error.message,
    });
  }
};

export const updateReceiveMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;

    const existing = await ReceiveMud.findOne({ _id: id, wellId });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Receive Mud record not found",
      });
    }

    await revertVolumeFromPit({
      wellId,
      to: existing.to,
      netVolume: toNumber(existing.netVolume),
    });

    const mergedPayload = {
      bolNo: req.body.bolNo ?? existing.bolNo,
      premixedMud: req.body.premixedMud ?? existing.premixedMud,
      mw: req.body.mw ?? existing.mw,
      mudType: req.body.mudType ?? existing.mudType,
      leasingFee: req.body.leasingFee ?? existing.leasingFee,
      from: req.body.from ?? existing.from,
      to: req.body.to ?? existing.to,
      volume: req.body.volume ?? existing.volume,
      leased: req.body.leased ?? existing.leased,
      lossVolume: req.body.lossVolume ?? existing.lossVolume,
    };

    const prepared = await prepareReceiveMudData(wellId, mergedPayload);

    await applyVolumeToPit({
      wellId,
      to: prepared.to,
      netVolume: prepared.netVolume,
      mw: prepared.mw,
      mudType: prepared.mudType,
    });

    existing.bolNo = prepared.bolNo;
    existing.premixedMud = prepared.premixedMud;
    existing.mw = prepared.mw;
    existing.mudType = prepared.mudType;
    existing.leasingFee = prepared.leasingFee;
    existing.from = prepared.from;
    existing.to = prepared.to;
    existing.volume = prepared.volume;
    existing.leased = prepared.leased;
    existing.lossVolume = prepared.lossVolume;
    existing.netVolume = prepared.netVolume;

    await existing.save();

    return res.status(200).json({
      success: true,
      message: "Receive Mud updated successfully",
      data: existing,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update Receive Mud",
      error: error.message,
    });
  }
};

export const deleteReceiveMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { id } = req.params;

    const existing = await ReceiveMud.findOne({ _id: id, wellId });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Receive Mud record not found",
      });
    }

    await revertVolumeFromPit({
      wellId,
      to: existing.to,
      netVolume: toNumber(existing.netVolume),
    });

    await ReceiveMud.deleteOne({ _id: id, wellId });

    return res.status(200).json({
      success: true,
      message: "Receive Mud deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete Receive Mud",
      error: error.message,
    });
  }
};