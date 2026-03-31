import Pit from "../../modules/pit/pit.model.js";
import OtherVolAddition from "../../modules/othervol/OtherVolAddition.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));

export const createOtherVolAddition = async (req, res) => {
  try {
    const { wellId, formation, cuttings, volumeNotFluid } = req.body;

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const safeWellId = String(wellId).trim();

    const formationVol = round2(toNumber(formation));
    const cuttingsVol = round2(toNumber(cuttings));
    const volumeNotFluidVol = round2(toNumber(volumeNotFluid));

    const totalVolume = round2(
      formationVol + cuttingsVol + volumeNotFluidVol
    );

    if (totalVolume <= 0) {
      return res.status(400).json({
        success: false,
        message: "At least one volume must be greater than 0",
      });
    }

    const activePits = await Pit.find({
      wellId: safeWellId,
      initialActive: true,
    }).sort({ createdAt: 1 });

    if (!activePits.length) {
      return res.status(404).json({
        success: false,
        message: "No active pits found for this wellId",
      });
    }

    // total volume active pits me evenly add karna
    let remaining = totalVolume;

    for (let i = 0; i < activePits.length; i++) {
      const pit = activePits[i];
      const pitsLeft = activePits.length - i;
      const add = round2(remaining / pitsLeft);

      pit.volume = round2(toNumber(pit.volume) + add);

      remaining = round2(remaining - add);
      await pit.save();
    }

    const item = await OtherVolAddition.create({
      wellId: safeWellId,
      formation: formationVol,
      cuttings: cuttingsVol,
      volumeNotFluid: volumeNotFluidVol,
      totalVolume,
    });

    return res.status(201).json({
      success: true,
      message: "Other volume addition saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to save Other Vol Addition",
      error: error.message,
    });
  }
};