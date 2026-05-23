import Pit from "../../modules/pit/pit.model.js";
import MudLoss from "../../modules/mudloss/MudLoss.js";
import { getWritablePits } from "../../utils/pitReportState.js";
import { buildScopedFilter, readReportId } from "../../utils/reportScope.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));
const getWellId = (req) => String(req.params.wellId || "").trim();

const deductFromActivePits = async ({ wellId, reportId, totalLoss }) => {
  return;
};

const revertToActivePits = async ({ wellId, reportId, totalLoss }) => {
  return;
};

export const createMudLoss = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const {
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
      extraLossLabel,
      extraLossVolume,
      operationInstanceKey,
    } = req.body;

    const extraLossVol = toNumber(extraLossVolume);
    const totalLoss = round2(
      toNumber(cuttingsRetention) +
        toNumber(seepage) +
        toNumber(dump) +
        toNumber(shakers) +
        toNumber(centrifuge) +
        toNumber(evaporation) +
        toNumber(pitCleaning) +
        toNumber(formation) +
        toNumber(abandonInHole) +
        toNumber(leftBehindCasing) +
        toNumber(tripping) +
        extraLossVol
    );

    if (totalLoss <= 0) {
      return res.status(400).json({
        success: false,
        message: "Total mud loss must be greater than 0",
      });
    }

    await deductFromActivePits({ wellId, reportId, totalLoss });

    const item = await MudLoss.create({
      wellId,
      reportId,
      cuttingsRetention: toNumber(cuttingsRetention),
      seepage: toNumber(seepage),
      dump: toNumber(dump),
      shakers: toNumber(shakers),
      centrifuge: toNumber(centrifuge),
      evaporation: toNumber(evaporation),
      pitCleaning: toNumber(pitCleaning),
      formation: toNumber(formation),
      abandonInHole: toNumber(abandonInHole),
      leftBehindCasing: toNumber(leftBehindCasing),
      tripping: toNumber(tripping),
      extraLossLabel: String(extraLossLabel || "").trim(),
      extraLossVolume: extraLossVol,
      operationInstanceKey: String(operationInstanceKey || "").trim(),
      totalLoss,
    });

    return res.status(201).json({
      success: true,
      message: "Mud Loss record saved successfully",
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

export const getMudLossList = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const items = await MudLoss.find(
      buildScopedFilter(wellId, reportId)
    ).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: items.length,
      data: items,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Mud Loss records",
      error: error.message,
    });
  }
};

export const getMudLossById = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const { id } = req.params;

    const item = await MudLoss.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!item) {
      return res.status(404).json({
        success: false,
        message: "Mud Loss record not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Mud Loss record",
      error: error.message,
    });
  }
};

export const updateMudLoss = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const { id } = req.params;

    const existing = await MudLoss.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Mud Loss record not found",
      });
    }

    // Revert old volume
    await revertToActivePits({
      wellId,
      reportId,
      totalLoss: toNumber(existing.totalLoss),
    });

    const updatedData = {
      cuttingsRetention: req.body.cuttingsRetention ?? existing.cuttingsRetention,
      seepage: req.body.seepage ?? existing.seepage,
      dump: req.body.dump ?? existing.dump,
      shakers: req.body.shakers ?? existing.shakers,
      centrifuge: req.body.centrifuge ?? existing.centrifuge,
      evaporation: req.body.evaporation ?? existing.evaporation,
      pitCleaning: req.body.pitCleaning ?? existing.pitCleaning,
      formation: req.body.formation ?? existing.formation,
      abandonInHole: req.body.abandonInHole ?? existing.abandonInHole,
      leftBehindCasing: req.body.leftBehindCasing ?? existing.leftBehindCasing,
      tripping: req.body.tripping ?? existing.tripping,
      extraLossLabel: req.body.extraLossLabel ?? existing.extraLossLabel,
      extraLossVolume: req.body.extraLossVolume ?? existing.extraLossVolume,
      operationInstanceKey:
        req.body.operationInstanceKey ?? existing.operationInstanceKey ?? "",
    };

    const extraLossVol = toNumber(updatedData.extraLossVolume);
    const totalLoss = round2(
      toNumber(updatedData.cuttingsRetention) +
        toNumber(updatedData.seepage) +
        toNumber(updatedData.dump) +
        toNumber(updatedData.shakers) +
        toNumber(updatedData.centrifuge) +
        toNumber(updatedData.evaporation) +
        toNumber(updatedData.pitCleaning) +
        toNumber(updatedData.formation) +
        toNumber(updatedData.abandonInHole) +
        toNumber(updatedData.leftBehindCasing) +
        toNumber(updatedData.tripping) +
        extraLossVol
    );

    updatedData.extraLossLabel = String(updatedData.extraLossLabel || "").trim();
    updatedData.extraLossVolume = extraLossVol;
    updatedData.operationInstanceKey = String(
      updatedData.operationInstanceKey || ""
    ).trim();

    await deductFromActivePits({ wellId, reportId, totalLoss });

    existing.set({ ...updatedData, totalLoss, reportId });
    await existing.save();

    return res.status(200).json({
      success: true,
      message: "Mud Loss record updated successfully",
      data: existing,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update Mud Loss",
      error: error.message,
    });
  }
};

export const deleteMudLoss = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const { id } = req.params;

    const existing = await MudLoss.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Mud Loss record not found",
      });
    }

    await revertToActivePits({
      wellId,
      reportId,
      totalLoss: toNumber(existing.totalLoss),
    });

    await MudLoss.deleteOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    return res.status(200).json({
      success: true,
      message: "Mud Loss record deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete Mud Loss",
      error: error.message,
    });
  }
};
