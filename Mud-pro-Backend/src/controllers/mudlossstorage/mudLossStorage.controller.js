import Pit from "../../modules/pit/pit.model.js";
import MudLossStorage from "../../modules/mudlossstorage/MudLossStorage.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));

export const createMudLossStorage = async (req, res) => {
  try {
    const { wellId, storage, dump, evaporation, pitCleaning } = req.body;

    if (!wellId || !storage) {
      return res.status(400).json({
        success: false,
        message: "wellId and storage are required",
      });
    }

    const safeWellId = String(wellId).trim();
    const safeStorage = String(storage).trim();

    const dumpVol = round2(toNumber(dump));
    const evaporationVol = round2(toNumber(evaporation));
    const pitCleaningVol = round2(toNumber(pitCleaning));

    const totalLoss = round2(dumpVol + evaporationVol + pitCleaningVol);

    if (totalLoss <= 0) {
      return res.status(400).json({
        success: false,
        message: "At least one storage mud loss value must be greater than 0",
      });
    }

    const sourcePit = await Pit.findOne({
      wellId: safeWellId,
      pitName: safeStorage,
      initialActive: false,
    });

    if (!sourcePit) {
      return res.status(404).json({
        success: false,
        message: `Storage pit '${storage}' not found`,
      });
    }

    const currentVol = round2(toNumber(sourcePit.volume));

    if (totalLoss > currentVol) {
      return res.status(400).json({
        success: false,
        message: `Mud loss (${totalLoss}) exceeds storage pit volume (${currentVol})`,
      });
    }

    sourcePit.volume = round2(currentVol - totalLoss);
    await sourcePit.save();

    const item = await MudLossStorage.create({
      wellId: safeWellId,
      storage: safeStorage,
      dump: dumpVol,
      evaporation: evaporationVol,
      pitCleaning: pitCleaningVol,
      totalLoss,
    });

    return res.status(201).json({
      success: true,
      message: "Mud Loss - Storage saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to save Mud Loss - Storage",
      error: error.message,
    });
  }
};