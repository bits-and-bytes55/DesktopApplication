import Pit from "../modules/pit/pit.model.js";
import Report from "../modules/report/report.model.js";

const toText = (value) => String(value ?? "").trim();
const toNumber = (value) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};
const round2 = (value) => Number(toNumber(value).toFixed(2));

export const activePitsVolumeForReport = async ({ wellId, reportId }) => {
  const cleanWellId = toText(wellId);
  const cleanReportId = toText(reportId);
  if (!cleanWellId || !cleanReportId) return 0;

  const activePits = await Pit.find({
    wellId: cleanWellId,
    reportId: cleanReportId,
    initialActive: true,
  }).lean();

  return round2(
    activePits.reduce((sum, pit) => sum + toNumber(pit.volume), 0)
  );
};

export const ensureVolumeNameActivePitsBaseline = async ({
  wellId,
  reportId,
}) => {
  const cleanWellId = toText(wellId);
  const cleanReportId = toText(reportId);
  if (!cleanWellId || !cleanReportId) return;

  const report = await Report.findOne({
    _id: cleanReportId,
    wellId: cleanWellId,
  }).lean();
  if (!report) return;
  if (
    report.volumeNameHoleActivePitsSnapshot !== null &&
    report.volumeNameHoleActivePitsSnapshot !== undefined
  ) {
    return;
  }

  const activePitsSnapshot = await activePitsVolumeForReport({
    wellId: cleanWellId,
    reportId: cleanReportId,
  });

  await Report.updateOne(
    { _id: cleanReportId, wellId: cleanWellId },
    { $set: { volumeNameHoleActivePitsSnapshot: activePitsSnapshot } }
  );
};
