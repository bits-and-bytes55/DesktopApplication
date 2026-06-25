import OtherVolAddition from "../../modules/othervol/OtherVolAddition.js";
import { buildScopedFilter, readReportId } from "../../utils/reportScope.js";
import { ensureVolumeNameActivePitsBaseline } from "../../utils/volumeNameBaseline.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));

const getWellId = (req) =>
  String(req.params.wellId || req.body.wellId || "").trim();

const prepareOtherVolAdditionData = (
  payload = {},
  fallbackWellId = "",
  fallbackReportId = ""
) => {
  const wellId = String(payload.wellId || fallbackWellId || "").trim();
  const reportId = String(payload.reportId || fallbackReportId || "").trim();
  const formationVol = round2(toNumber(payload.formation));
  const cuttingsVol = round2(toNumber(payload.cuttings));
  const volumeNotFluidVol = round2(toNumber(payload.volumeNotFluid));

  if (!wellId) {
    throw new Error("wellId is required");
  }

  const totalVolume = round2(
    formationVol + cuttingsVol + volumeNotFluidVol
  );

  if (formationVol < 0 || cuttingsVol < 0 || volumeNotFluidVol < 0) {
    throw new Error("Volumes cannot be negative");
  }

  if (totalVolume <= 0) {
    throw new Error("At least one volume must be greater than 0");
  }

  return {
    wellId,
    reportId,
    operationInstanceKey: String(payload.operationInstanceKey || "").trim(),
    formation: formationVol,
    cuttings: cuttingsVol,
    volumeNotFluid: volumeNotFluidVol,
    totalVolume,
  };
};

const addToActivePits = async ({ wellId, reportId, totalVolume }) => {
  return;
};

const revertFromActivePits = async ({ wellId, reportId, totalVolume }) => {
  return;
};

export const createOtherVolAddition = async (req, res) => {
  try {
    const fallbackWellId = getWellId(req);
    const fallbackReportId = readReportId(req);
    if (!fallbackReportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required for Other Vol Addition",
      });
    }
    const payloads = Array.isArray(req.body) ? req.body : [req.body];

    if (!payloads.length) {
      return res.status(400).json({
        success: false,
        message: "Request body is empty",
      });
    }

    const createdItems = [];

    for (const payload of payloads) {
      const prepared = prepareOtherVolAdditionData(
        payload,
        fallbackWellId,
        fallbackReportId
      );
      await ensureVolumeNameActivePitsBaseline({
        wellId: prepared.wellId,
        reportId: prepared.reportId,
      });

      await addToActivePits({
        wellId: prepared.wellId,
        reportId: prepared.reportId,
        totalVolume: prepared.totalVolume,
      });

      const item = await OtherVolAddition.create(prepared);
      createdItems.push(item);
    }

    return res.status(201).json({
      success: true,
      message:
        createdItems.length === 1
          ? "Other volume addition saved successfully"
          : "Multiple other volume addition records saved successfully",
      count: createdItems.length,
      data: createdItems,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to save Other Vol Addition",
      error: error.message,
    });
  }
};

export const getOtherVolAdditionList = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    if (!reportId) {
      return res.status(200).json({
        success: true,
        count: 0,
        data: [],
      });
    }

    const items = await OtherVolAddition.find(
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
      message: "Failed to fetch Other Vol Addition records",
      error: error.message,
    });
  }
};

export const getOtherVolAdditionById = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required for Other Vol Addition",
      });
    }
    const { id } = req.params;

    const item = await OtherVolAddition.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!item) {
      return res.status(404).json({
        success: false,
        message: "Other Vol Addition record not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Other Vol Addition record",
      error: error.message,
    });
  }
};

export const updateOtherVolAddition = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required for Other Vol Addition",
      });
    }
    const { id } = req.params;

    const existing = await OtherVolAddition.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Other Vol Addition record not found",
      });
    }

    await revertFromActivePits({
      wellId: existing.wellId,
      reportId,
      totalVolume: toNumber(existing.totalVolume),
    });

    const mergedPayload = {
      wellId: req.body.wellId ?? existing.wellId,
      reportId: req.body.reportId ?? existing.reportId ?? reportId,
      operationInstanceKey:
        req.body.operationInstanceKey ?? existing.operationInstanceKey ?? "",
      formation: req.body.formation ?? existing.formation,
      cuttings: req.body.cuttings ?? existing.cuttings,
      volumeNotFluid: req.body.volumeNotFluid ?? existing.volumeNotFluid,
    };

    const prepared = prepareOtherVolAdditionData(mergedPayload);
    await ensureVolumeNameActivePitsBaseline({
      wellId: prepared.wellId,
      reportId: prepared.reportId,
    });

    await addToActivePits({
      wellId: prepared.wellId,
      reportId: prepared.reportId,
      totalVolume: prepared.totalVolume,
    });

    existing.wellId = prepared.wellId;
    existing.reportId = prepared.reportId;
    existing.operationInstanceKey = prepared.operationInstanceKey;
    existing.formation = prepared.formation;
    existing.cuttings = prepared.cuttings;
    existing.volumeNotFluid = prepared.volumeNotFluid;
    existing.totalVolume = prepared.totalVolume;

    await existing.save();

    return res.status(200).json({
      success: true,
      message: "Other Vol Addition updated successfully",
      data: existing,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update Other Vol Addition",
      error: error.message,
    });
  }
};

export const deleteOtherVolAddition = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required for Other Vol Addition",
      });
    }
    const { id } = req.params;

    const existing = await OtherVolAddition.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Other Vol Addition record not found",
      });
    }

    await revertFromActivePits({
      wellId: existing.wellId,
      reportId,
      totalVolume: toNumber(existing.totalVolume),
    });

    await OtherVolAddition.deleteOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    return res.status(200).json({
      success: true,
      message: "Other Vol Addition deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete Other Vol Addition",
      error: error.message,
    });
  }
};
