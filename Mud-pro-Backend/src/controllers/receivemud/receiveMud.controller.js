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

export const createReceiveMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
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
    } = req.body;

    if (!wellId || !premixedMud || !to || volume === undefined || volume === null) {
      return res.status(400).json({
        success: false,
        message: "wellId, premixedMud, to and volume are required",
      });
    }

    const grossVolume = round2(toNumber(volume));
    const loss = round2(toNumber(lossVolume));
    const netVolume = round2(grossVolume - loss);

    if (grossVolume <= 0) {
      return res.status(400).json({
        success: false,
        message: "Volume must be greater than 0",
      });
    }

    if (loss < 0 || loss > grossVolume) {
      return res.status(400).json({
        success: false,
        message: "Loss Volume must be between 0 and volume",
      });
    }

    const premixed = await Premixed.findOne({
      wellId,
      description: { $regex: `^${String(premixedMud).trim()}$`, $options: "i" },
    });

    if (!premixed) {
      return res.status(404).json({
        success: false,
        message: `Premixed mud '${premixedMud}' not found for this well`,
      });
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

    const allPits = await Pit.find({ wellId }).sort({ createdAt: 1 });

    if (!allPits.length) {
      return res.status(404).json({
        success: false,
        message: "No pits found for this wellId",
      });
    }

    if (String(to).trim() === "Active System") {
      const activePits = allPits.filter((pit) => pit.initialActive === true);

      if (!activePits.length) {
        return res.status(400).json({
          success: false,
          message: "No active pits found",
        });
      }

      let remaining = netVolume;

      for (let i = 0; i < activePits.length; i++) {
        const pit = activePits[i];
        const pitsLeft = activePits.length - i;
        const add = round2(remaining / pitsLeft);

        pit.volume = round2(toNumber(pit.volume) + add);
        pit.density = finalMw;
        pit.fluidType = finalMudType;

        remaining = round2(remaining - add);
        await pit.save();
      }
    } else {
      const targetPit = await Pit.findOne({
        wellId,
        pitName: String(to).trim(),
      });

      if (!targetPit) {
        return res.status(404).json({
          success: false,
          message: `Target pit '${to}' not found`,
        });
      }

      targetPit.volume = round2(toNumber(targetPit.volume) + netVolume);
      targetPit.density = finalMw;
      targetPit.fluidType = finalMudType;

      await targetPit.save();
    }

    const item = await ReceiveMud.create({
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
    });

    return res.status(201).json({
      success: true,
      message: "Receive Mud saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to save Receive Mud",
      error: error.message,
    });
  }
};