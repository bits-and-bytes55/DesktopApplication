import Pit from "../../modules/pit/pit.model.js";
import MudLoss from "../../modules/mudloss/MudLoss.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));

export const createMudLoss = async (req, res) => {
  try {
    const {
      wellId,
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

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const safeWellId = String(wellId).trim();

    const lossData = {
      cuttingsRetention: round2(toNumber(cuttingsRetention)),
      seepage: round2(toNumber(seepage)),
      dump: round2(toNumber(dump)),
      shakers: round2(toNumber(shakers)),
      centrifuge: round2(toNumber(centrifuge)),
      evaporation: round2(toNumber(evaporation)),
      pitCleaning: round2(toNumber(pitCleaning)),
      formation: round2(toNumber(formation)),
      abandonInHole: round2(toNumber(abandonInHole)),
      leftBehindCasing: round2(toNumber(leftBehindCasing)),
      tripping: round2(toNumber(tripping)),
    };

    const totalLoss = round2(
      Object.values(lossData).reduce((sum, val) => sum + val, 0)
    );

    if (totalLoss <= 0) {
      return res.status(400).json({
        success: false,
        message: "At least one mud loss value must be greater than 0",
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

    const totalActiveVol = round2(
      activePits.reduce((sum, pit) => sum + toNumber(pit.volume), 0)
    );

    if (totalLoss > totalActiveVol) {
      return res.status(400).json({
        success: false,
        message: `Mud loss (${totalLoss}) exceeds active system volume (${totalActiveVol})`,
      });
    }

    // active system se evenly minus
    let remaining = totalLoss;

    for (let i = 0; i < activePits.length; i++) {
      const pit = activePits[i];
      if (remaining <= 0) break;

      const pitsLeft = activePits.length - i;
      let deduct = round2(remaining / pitsLeft);

      if (deduct > toNumber(pit.volume)) {
        deduct = round2(toNumber(pit.volume));
      }

      pit.volume = round2(toNumber(pit.volume) - deduct);
      remaining = round2(remaining - deduct);

      await pit.save();
    }

    // safety pass
    if (remaining > 0) {
      for (const pit of activePits) {
        if (remaining <= 0) break;

        const available = toNumber(pit.volume);
        if (available <= 0) continue;

        const deduct = Math.min(available, remaining);
        pit.volume = round2(available - deduct);
        remaining = round2(remaining - deduct);

        await pit.save();
      }
    }

    if (remaining > 0) {
      return res.status(400).json({
        success: false,
        message: "Unable to deduct full mud loss from active pits",
      });
    }

    const item = await MudLoss.create({
      wellId: safeWellId,
      ...lossData,
      totalLoss,
    });

    return res.status(201).json({
      success: true,
      message: "Mud Loss saved successfully",
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