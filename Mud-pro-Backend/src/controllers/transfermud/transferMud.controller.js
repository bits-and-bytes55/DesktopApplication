import Pit from "../../modules/pit/pit.model.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));

export const transferMud = async (req, res) => {
  try {
    const { wellId, from, transfers } = req.body;

    if (!wellId || !from || !Array.isArray(transfers) || transfers.length === 0) {
      return res.status(400).json({
        success: false,
        message: "wellId, from, and transfers are required",
      });
    }

    const cleanTransfers = transfers
      .map((item) => ({
        pitName: String(item.pitName || "").trim(),
        volume: round2(toNumber(item.volume)),
      }))
      .filter((item) => item.pitName && item.volume > 0);

    if (cleanTransfers.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Valid transfer rows are required",
      });
    }

    const totalTransferVol = round2(
      cleanTransfers.reduce((sum, item) => sum + item.volume, 0)
    );

    const allPits = await Pit.find({ wellId }).sort({ createdAt: 1 });

    if (!allPits.length) {
      return res.status(404).json({
        success: false,
        message: "No pits found for this wellId",
      });
    }

    const activePits = allPits.filter((pit) => pit.initialActive === true);
    const storagePits = allPits.filter((pit) => pit.initialActive === false);

    const totalActiveVol = round2(
      activePits.reduce((sum, pit) => sum + toNumber(pit.volume), 0)
    );

    // ---------------------------------------------------
    // CASE 1: FROM ACTIVE SYSTEM -> STORAGE PITS
    // ---------------------------------------------------
    if (from === "Active System") {
      if (!activePits.length) {
        return res.status(400).json({
          success: false,
          message: "No active pits found",
        });
      }

      if (totalTransferVol > totalActiveVol) {
        return res.status(400).json({
          success: false,
          message: `Transfer volume (${totalTransferVol}) exceeds active pits volume (${totalActiveVol})`,
        });
      }

      // 1. target storage pits me volume add karo
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

      // 2. active pits se evenly minus karo
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

      // safety second pass
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
        return res.status(400).json({
          success: false,
          message: "Unable to deduct full transfer volume from active pits",
        });
      }

      return res.status(200).json({
        success: true,
        message: "Mud transferred from Active System to Storage successfully",
        data: {
          wellId,
          from,
          totalTransferVol,
          transfers: cleanTransfers,
        },
      });
    }

    // ---------------------------------------------------
    // CASE 2: FROM STORAGE PIT -> ACTIVE SYSTEM
    // ---------------------------------------------------
    const sourceStoragePit = storagePits.find((pit) => pit.pitName === from);

    if (!sourceStoragePit) {
      return res.status(404).json({
        success: false,
        message: `Source storage pit '${from}' not found`,
      });
    }

    const totalOutgoing = totalTransferVol;

    if (totalOutgoing > toNumber(sourceStoragePit.volume)) {
      return res.status(400).json({
        success: false,
        message: `Transfer volume (${totalOutgoing}) exceeds source pit volume (${toNumber(sourceStoragePit.volume)})`,
      });
    }

    for (const item of cleanTransfers) {
      if (item.pitName !== "Active System") {
        return res.status(400).json({
          success: false,
          message: "When source is storage, destination must be 'Active System'",
        });
      }
    }

    if (!activePits.length) {
      return res.status(400).json({
        success: false,
        message: "No active pits found",
      });
    }

    // source storage se minus
    sourceStoragePit.volume = round2(toNumber(sourceStoragePit.volume) - totalOutgoing);
    await sourceStoragePit.save();

    // active pits me evenly add
    let remainingToAdd = totalOutgoing;

    for (let i = 0; i < activePits.length; i++) {
      const pit = activePits[i];
      const pitsLeft = activePits.length - i;
      const add = round2(remainingToAdd / pitsLeft);

      pit.volume = round2(toNumber(pit.volume) + add);
      remainingToAdd = round2(remainingToAdd - add);

      await pit.save();
    }

    return res.status(200).json({
      success: true,
      message: "Mud transferred from Storage to Active System successfully",
      data: {
        wellId,
        from,
        totalTransferVol,
        transfers: cleanTransfers,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Transfer mud failed",
      error: error.message,
    });
  }
};