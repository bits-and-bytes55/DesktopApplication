import MudReportState from "../../modules/mudReport/MudReportState.js";

const text = (value, fallback = "") => {
  const parsed = value?.toString().trim();
  return parsed ? parsed : fallback;
};

const normalizedReportId = (value) => text(value);

const buildPayload = (body = {}, wellId) => ({
  wellId,
  reportId: normalizedReportId(body.reportId),
  fluidName: text(body.fluidName),
  fluidType: text(body.fluidType),
  isCompletionFluid: Boolean(body.isCompletionFluid),
  isWeightedMud: Boolean(body.isWeightedMud),
  samples: Array.isArray(body.samples) ? body.samples.map((item) => text(item)) : [],
  propertyTable: body.propertyTable && typeof body.propertyTable === "object" ? body.propertyTable : {},
  propertyUnits: body.propertyUnits && typeof body.propertyUnits === "object" ? body.propertyUnits : {},
  rheologyModel: text(body.rheologyModel),
  rheologyCalculation: text(body.rheologyCalculation),
  rheologyTable: body.rheologyTable && typeof body.rheologyTable === "object" ? body.rheologyTable : {},
  sampleForCalculation: text(body.sampleForCalculation),
  oilSg: text(body.oilSg),
  hgsSg: text(body.hgsSg),
  lgsSg: text(body.lgsSg),
  shaleCec: text(body.shaleCec),
  bentCec: text(body.bentCec),
});

const findState = async ({ wellId, reportId }) => {
  const scopedReportId = normalizedReportId(reportId);

  if (scopedReportId) {
    return MudReportState.findOne({ wellId, reportId: scopedReportId })
      .sort({ updatedAt: -1, _id: -1 })
      .lean();
  }

  const legacy = await MudReportState.findOne({
    wellId,
    $or: [{ reportId: "" }, { reportId: null }, { reportId: { $exists: false } }],
  })
    .sort({ updatedAt: -1, _id: -1 })
    .lean();
  if (legacy) return legacy;

  return MudReportState.findOne({ wellId })
    .sort({ updatedAt: -1, _id: -1 })
    .lean();
};

export const getMudReportState = async (req, res) => {
  try {
    const wellId = text(req.params.wellId);
    if (!wellId) {
      return res.status(400).json({ success: false, message: "wellId is required" });
    }

    const record = await findState({ wellId, reportId: req.query.reportId });
    return res.status(200).json({ success: true, data: record || null });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

export const saveMudReportState = async (req, res) => {
  try {
    const wellId = text(req.params.wellId || req.body.wellId);
    if (!wellId) {
      return res.status(400).json({ success: false, message: "wellId is required" });
    }

    const payload = buildPayload(req.body, wellId);
    const record = await MudReportState.findOneAndUpdate(
      { wellId, reportId: payload.reportId },
      { $set: payload },
      { upsert: true, returnDocument: "after", runValidators: true, setDefaultsOnInsert: true }
    );

    return res.status(200).json({
      success: true,
      message: "Mud report data saved",
      data: record,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
