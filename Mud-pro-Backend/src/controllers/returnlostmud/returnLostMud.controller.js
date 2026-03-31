import Pit from "../../modules/pit/pit.model.js";
import Premixed from "../../modules/inventory/premixed.model.js";
import ReturnLostMud from "../../modules/returnlostmud/ReturnLostMud.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));

export const createReturnLostMud = async (req, res) => {
  try {
    const {
      wellId,
      premixedMud,
      from,
      to,
      volReturned,
      mw,
      mudType,
      bol,
      volLost,
      costOfLostPreTax,
      leased,
    } = req.body;

    if (!wellId || !premixedMud || !from || !to) {
      return res.status(400).json({
        success: false,
        message: "wellId, premixedMud, from and to are required",
      });
    }

    const safeWellId = String(wellId).trim();
    const safePremixedMud = String(premixedMud).trim();
    const safeFrom = String(from).trim();
    const safeTo = String(to).trim();

    const returned = round2(toNumber(volReturned));
    const lost = round2(toNumber(volLost));
    const totalDeduct = round2(returned + lost);

    if (returned < 0 || lost < 0) {
      return res.status(400).json({
        success: false,
        message: "volReturned and volLost cannot be negative",
      });
    }

    if (returned === 0 && lost === 0) {
      return res.status(400).json({
        success: false,
        message: "Either volReturned or volLost must be greater than 0",
      });
    }

    const premixed = await Premixed.findOne({
      wellId: safeWellId,
      description: { $regex: `^${safePremixedMud}$`, $options: "i" },
    });

    if (!premixed) {
      const availablePremixed = await Premixed.find({ wellId: safeWellId }).select("description");

      return res.status(404).json({
        success: false,
        message: `Premixed mud '${premixedMud}' not found for this well`,
        availablePremixed: availablePremixed.map((item) => item.description),
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

    const premixedLeasingFee = round2(toNumber(premixed.leasingFee));

    const finalCostOfLostPreTax =
      costOfLostPreTax !== undefined && costOfLostPreTax !== null && costOfLostPreTax !== ""
        ? round2(toNumber(costOfLostPreTax))
        : round2(lost * premixedLeasingFee);

    const allPits = await Pit.find({ wellId: safeWellId }).sort({ createdAt: 1 });

    if (!allPits.length) {
      return res.status(404).json({
        success: false,
        message: "No pits found for this wellId",
      });
    }

    // ----------------------------
    // SOURCE SE VOLUME MINUS HOGA
    // ----------------------------
    if (safeFrom === "Active System") {
      const activePits = allPits.filter((pit) => pit.initialActive === true);

      if (!activePits.length) {
        return res.status(400).json({
          success: false,
          message: "No active pits found",
        });
      }

      const totalActiveVol = round2(
        activePits.reduce((sum, pit) => sum + toNumber(pit.volume), 0)
      );

      if (totalDeduct > totalActiveVol) {
        return res.status(400).json({
          success: false,
          message: `Total deduct volume (${totalDeduct}) exceeds Active System volume (${totalActiveVol})`,
        });
      }

      let remaining = totalDeduct;

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

      if (remaining > 0) {
        return res.status(400).json({
          success: false,
          message: "Unable to deduct full volume from Active System",
        });
      }
    } else {
      const sourcePit = await Pit.findOne({
        wellId: safeWellId,
        pitName: safeFrom,
      });

      if (!sourcePit) {
        return res.status(404).json({
          success: false,
          message: `Source pit '${from}' not found`,
        });
      }

      if (totalDeduct > toNumber(sourcePit.volume)) {
        return res.status(400).json({
          success: false,
          message: `Total deduct volume (${totalDeduct}) exceeds source pit volume (${toNumber(sourcePit.volume)})`,
        });
      }

      sourcePit.volume = round2(toNumber(sourcePit.volume) - totalDeduct);
      await sourcePit.save();
    }

    // ----------------------------
    // RETURNED VOLUME DESTINATION ME ADD HOGA
    // LOST VOLUME SIRF RECORD HOGA
    // ----------------------------
    if (returned > 0) {
      if (safeTo === "Active System") {
        const activePits = allPits.filter((pit) => pit.initialActive === true);

        if (!activePits.length) {
          return res.status(400).json({
            success: false,
            message: "No active pits found",
          });
        }

        let remaining = returned;

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
      } else if (safeTo !== "Imp") {
        // Imp ko external maan rahe hain, isliye pit add nahi karenge
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

        targetPit.volume = round2(toNumber(targetPit.volume) + returned);
        targetPit.density = finalMw;
        targetPit.fluidType = finalMudType;

        await targetPit.save();
      }
    }

    const item = await ReturnLostMud.create({
      wellId: safeWellId,
      premixedMud: safePremixedMud,
      from: safeFrom,
      to: safeTo,
      volReturned: returned,
      mw: finalMw,
      mudType: finalMudType,
      bol: round2(toNumber(bol)),
      volLost: lost,
      costOfLostPreTax: finalCostOfLostPreTax,
      leased: leased === true || leased === "true",
    });

    return res.status(201).json({
      success: true,
      message: "Return / Lost Mud saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to save Return / Lost Mud",
      error: error.message,
    });
  }
};