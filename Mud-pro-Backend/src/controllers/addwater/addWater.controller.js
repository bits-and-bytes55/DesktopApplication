import Pit from "../../modules/pit/pit.model.js";
import AddWater from "../../modules/addwater/AddWater.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));

export const createAddWater = async (req, res) => {
  try {
    const { wellId, to, volume } = req.body;

    if (!wellId || !to || volume === undefined || volume === null) {
      return res.status(400).json({
        success: false,
        message: "wellId, to and volume are required",
      });
    }

    const safeWellId = String(wellId).trim();
    const safeTo = String(to).trim();
    const waterVol = round2(toNumber(volume));

    if (waterVol <= 0) {
      return res.status(400).json({
        success: false,
        message: "Volume must be greater than 0",
      });
    }

    const allPits = await Pit.find({ wellId: safeWellId }).sort({ createdAt: 1 });

    if (!allPits.length) {
      return res.status(404).json({
        success: false,
        message: "No pits found for this wellId",
      });
    }

    // CASE 1: To = Active System
    if (safeTo === "Active System") {
      const activePits = allPits.filter((pit) => pit.initialActive === true);

      if (!activePits.length) {
        return res.status(400).json({
          success: false,
          message: "No active pits found",
        });
      }

      let remaining = waterVol;

      for (let i = 0; i < activePits.length; i++) {
        const pit = activePits[i];
        const pitsLeft = activePits.length - i;
        const add = round2(remaining / pitsLeft);

        pit.volume = round2(toNumber(pit.volume) + add);

        // optional: water add hone par fluidType set karna ho to uncomment
        // pit.fluidType = "Water";

        remaining = round2(remaining - add);
        await pit.save();
      }
    } else {
      // CASE 2: Specific pit
      const targetPit = await Pit.findOne({
        wellId: safeWellId,
        pitName: safeTo,
      });

      if (!targetPit) {
        return res.status(404).json({
          success: false,
          message: `Target pit '${to}' not found`,
        });
      }

      targetPit.volume = round2(toNumber(targetPit.volume) + waterVol);

      // optional
      // targetPit.fluidType = targetPit.fluidType || "Water";

      await targetPit.save();
    }

    const item = await AddWater.create({
      wellId: safeWellId,
      to: safeTo,
      volume: waterVol,
    });

    return res.status(201).json({
      success: true,
      message: "Add Water saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to save Add Water",
      error: error.message,
    });
  }
};