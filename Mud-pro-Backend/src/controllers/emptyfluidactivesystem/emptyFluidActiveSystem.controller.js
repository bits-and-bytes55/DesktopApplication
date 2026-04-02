import Pit from "../../modules/pit/pit.model.js";
import EmptyFluidActiveSystem from "../../modules/emptyfluidactivesystem/EmptyFluidActiveSystem.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));
const getWellId = (req) => String(req.params.wellId || "").trim();

export const createEmptyFluidActiveSystem = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const { actionType, transfers = [], volume } = req.body;

    if (!wellId || !actionType) {
      return res.status(400).json({
        success: false,
        message: "wellId and actionType are required",
      });
    }

    const allPits = await Pit.find({ wellId }).sort({ createdAt: 1 });

    if (!allPits.length) {
      return res.status(404).json({
        success: false,
        message: "No pits found for this wellId",
      });
    }

    const activePits = allPits.filter((pit) => pit.initialActive === true);
    const storagePits = allPits.filter((pit) => pit.initialActive === false);

    if (!activePits.length) {
      return res.status(400).json({
        success: false,
        message: "No active pits found",
      });
    }

    const totalActiveVol = round2(
      activePits.reduce((sum, pit) => sum + toNumber(pit.volume), 0)
    );

    // -----------------------------------
    // CASE 1: DUMP
    // body example:
    // { actionType: "Dump", volume: 20 }
    // -----------------------------------
    if (actionType === "Dump") {
      const dumpVol = round2(toNumber(volume));

      if (dumpVol <= 0) {
        return res.status(400).json({
          success: false,
          message: "Volume must be greater than 0 for Dump",
        });
      }

      if (dumpVol > totalActiveVol) {
        return res.status(400).json({
          success: false,
          message: `Dump volume (${dumpVol}) exceeds Active System volume (${totalActiveVol})`,
        });
      }

      let remaining = dumpVol;

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
          message: "Unable to deduct full dump volume from active pits",
        });
      }

      const item = await EmptyFluidActiveSystem.create({
        wellId,
        actionType,
        pitName: "",
        volume: dumpVol,
        totalVolume: dumpVol,
      });

      return res.status(201).json({
        success: true,
        message: "Empty Fluid dumped from Active System successfully",
        data: item,
      });
    }

    // -----------------------------------
    // CASE 2: TRANSFER TO STORAGE
    // body example:
    // {
    //   actionType: "Transfer to Storage",
    //   transfers: [{ pitName: "c", volume: 20 }]
    // }
    // -----------------------------------
    if (actionType === "Transfer to Storage") {
      const cleanTransfers = Array.isArray(transfers)
        ? transfers
            .map((item) => ({
              pitName: String(item.pitName || "").trim(),
              volume: round2(toNumber(item.volume)),
            }))
            .filter((item) => item.pitName && item.volume > 0)
        : [];

      if (!cleanTransfers.length) {
        return res.status(400).json({
          success: false,
          message: "Valid transfers are required for Transfer to Storage",
        });
      }

      const totalTransferVol = round2(
        cleanTransfers.reduce((sum, item) => sum + item.volume, 0)
      );

      if (totalTransferVol > totalActiveVol) {
        return res.status(400).json({
          success: false,
          message: `Transfer volume (${totalTransferVol}) exceeds Active System volume (${totalActiveVol})`,
        });
      }

      // destination storage pits me add
      for (const item of cleanTransfers) {
        const targetPit = storagePits.find((pit) => pit.pitName === item.pitName);

        if (!targetPit) {
          return res.status(404).json({
            success: false,
            message: `Storage pit '${item.pitName}' not found`,
          });
        }

        targetPit.volume = round2(toNumber(targetPit.volume) + item.volume);
        await targetPit.save();
      }

      // active pits se minus
      let remaining = totalTransferVol;

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
          message: "Unable to deduct full transfer volume from active pits",
        });
      }

      const items = await EmptyFluidActiveSystem.insertMany(
        cleanTransfers.map((item) => ({
          wellId,
          actionType,
          pitName: item.pitName,
          volume: item.volume,
          totalVolume: totalTransferVol,
        }))
      );

      return res.status(201).json({
        success: true,
        message: "Empty Fluid transferred from Active System to Storage successfully",
        data: items,
      });
    }

    return res.status(400).json({
      success: false,
      message: "Invalid actionType. Use 'Dump' or 'Transfer to Storage'",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to save Empty Fluid in Active System",
      error: error.message,
    });
  }
};