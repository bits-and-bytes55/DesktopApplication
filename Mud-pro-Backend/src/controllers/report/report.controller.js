import mongoose from "mongoose";
import Report from "../../modules/report/report.model.js";
import Well from "../../modules/well/well.model.js";
import WellGeneral from "../../modules/wellGeneral/wellGeneralModel.js";
import Pit from "../../modules/pit/pit.model.js";
import Pump from "../../modules/pump/pump.model.js";
import Nozzle from "../../modules/nozzle/nozzle.model.js";
import { Shaker, OtherSce } from "../../modules/sce/sce.model.js";
import InventorySnapshot from "../../modules/FullInventory/InventorySnapshot.js";
import MudReportState from "../../modules/mudReport/MudReportState.js";

const toText = (value) => String(value ?? "").trim();

const toNumber = (value, fallback = 0) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const round2 = (value) => Number(toNumber(value).toFixed(2));

const sanitizePumpRateAndPressure = (value = {}) => {
  const source =
    value && typeof value === "object" && !Array.isArray(value) ? value : {};

  return {
    pumpRate: toNumber(source.pumpRate),
    pumpPressure: toNumber(source.pumpPressure),
    boostPumpRate: toNumber(source.boostPumpRate),
    returnRate: toNumber(source.returnRate),
    dhToolsPressureLoss: toNumber(source.dhToolsPressureLoss),
    motorPressureLoss: toNumber(source.motorPressureLoss),
  };
};

const sanitizeRemarksAttachment = (value) => {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }

  const fileName = toText(value.fileName || value.name);
  const mimeType = toText(value.mimeType || value.type);
  const data = toText(value.data || value.base64);
  const size = toNumber(value.size);

  if (!fileName && !data) {
    return null;
  }

  return {
    fileName,
    mimeType,
    size,
    data,
  };
};

const hasPumpRateAndPressureInput = (value) =>
  value && typeof value === "object" && !Array.isArray(value);

const escapeRegex = (value) =>
  String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const normalizeKey = (value) =>
  toText(value)
    .toLowerCase()
    .replaceAll("*", "")
    .replace(/\s+/g, " ")
    .trim();

const latestTimestamp = (item) =>
  new Date(item?.updatedAt ?? item?.createdAt ?? 0).getTime();

const firstMeaningfulText = (...values) => {
  for (const value of values) {
    const parsed = toText(value);
    if (parsed) return parsed;
  }
  return "";
};

const firstPositiveNumber = (...values) => {
  for (const value of values) {
    const parsed = toNumber(value, NaN);
    if (Number.isFinite(parsed) && parsed > 0) {
      return parsed;
    }
  }
  return 0;
};

const pickLatestByKey = (items = [], getKey) => {
  const sorted = [...items].sort(
    (left, right) => latestTimestamp(right) - latestTimestamp(left)
  );
  const byKey = new Map();

  for (const item of sorted) {
    const key = toText(getKey(item));
    if (!key || byKey.has(key)) continue;
    byKey.set(key, item);
  }

  return byKey;
};

const firstPositiveFromList = (value) => {
  if (Array.isArray(value)) {
    for (const item of value) {
      const parsed = toNumber(item, NaN);
      if (Number.isFinite(parsed) && parsed > 0) {
        return parsed;
      }
    }
  }

  const parsed = toNumber(value, NaN);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 0;
};

const extractMudWeight = (propertyTable = {}) => {
  if (!propertyTable || typeof propertyTable !== "object" || Array.isArray(propertyTable)) {
    return 0;
  }

  for (const [key, value] of Object.entries(propertyTable)) {
    const normalized = normalizeKey(key);
    if (
      normalized === "mw" ||
      normalized.startsWith("mw ") ||
      normalized.includes("mud weight")
    ) {
      const parsed = firstPositiveFromList(value);
      if (parsed > 0) {
        return parsed;
      }
    }
  }

  return 0;
};

const buildInventorySummaryByReportId = (rows = []) => {
  const byReportId = new Map();

  const sorted = [...rows].sort(
    (left, right) => latestTimestamp(right) - latestTimestamp(left)
  );

  for (const row of sorted) {
    const reportId = toText(row.reportId);
    if (!reportId || byReportId.has(reportId)) continue;

    byReportId.set(reportId, {
      dailyCost: round2(row.dailyTotal || row.totalDollar),
      cumulativeCost: round2(row.cumTotal || row.totalDollar),
    });
  }

  return byReportId;
};

const buildPitSummaryByReportId = (rows = []) => {
  const byReportId = new Map();

  const sorted = [...rows].sort(
    (left, right) => latestTimestamp(right) - latestTimestamp(left)
  );

  for (const row of sorted) {
    const reportId = toText(row.reportId);
    if (!reportId || byReportId.has(reportId)) continue;

    byReportId.set(reportId, {
      mudType: toText(row.fluidType),
      mw: round2(row.density),
    });
  }

  return byReportId;
};

const ensureWellExists = async (wellId) => {
  if (!mongoose.Types.ObjectId.isValid(wellId)) {
    return { ok: false, status: 400, message: "Invalid wellId" };
  }

  const well = await Well.findById(wellId).lean();
  if (!well) {
    return { ok: false, status: 404, message: "Well not found" };
  }

  return { ok: true, well };
};

const nextReportNoForWell = async (wellId) => {
  const reports = await Report.find({ wellId }).select("reportNo").lean();
  let maxNumber = 0;

  for (const report of reports) {
    const parsed = Number.parseInt(String(report.reportNo || "").trim(), 10);
    if (Number.isFinite(parsed) && parsed > maxNumber) {
      maxNumber = parsed;
    }
  }

  return String(maxNumber + 1);
};

const cleanClone = (doc = {}) => {
  const clone = { ...doc };
  delete clone._id;
  delete clone.id;
  delete clone.__v;
  delete clone.createdAt;
  delete clone.updatedAt;
  return clone;
};

const legacyPitScopeFilter = (wellId) => ({
  wellId,
  $or: [{ reportId: { $exists: false } }, { reportId: null }, { reportId: "" }],
});

const legacyScopedFilter = (wellId) => ({
  wellId,
  $or: [{ reportId: { $exists: false } }, { reportId: null }],
});

const sortByCreatedAtAsc = (items = []) =>
  [...items].sort((left, right) => {
    const leftTime = new Date(left.createdAt ?? 0).getTime();
    const rightTime = new Date(right.createdAt ?? 0).getTime();
    return leftTime - rightTime;
  });

const dedupeLatestPits = (items = []) => {
  const latestByName = new Map();

  for (const item of items) {
    const key = toText(item.pitName).toLowerCase();
    if (!key || latestByName.has(key)) continue;
    latestByName.set(key, item);
  }

  return sortByCreatedAtAsc(Array.from(latestByName.values()));
};

const findSourceReport = async (wellId, reportId) => {
  if (!mongoose.Types.ObjectId.isValid(reportId)) {
    return null;
  }

  return Report.findOne({ _id: reportId, wellId }).lean();
};

const loadSourceWellGeneral = async ({ wellId, sourceReport }) => {
  const sourceReportId = toText(sourceReport?._id);
  if (sourceReportId) {
    const byReportId = await WellGeneral.findOne({
      wellId,
      reportId: sourceReportId,
    })
      .sort({ updatedAt: -1, createdAt: -1 })
      .lean();

    if (byReportId) {
      return byReportId;
    }
  }

  const sourceReportNo = toText(sourceReport?.reportNo);
  if (sourceReportNo) {
    const byReportNo = await WellGeneral.findOne({
      wellId,
      reportNo: sourceReportNo,
    })
      .sort({ updatedAt: -1, createdAt: -1 })
      .lean();

    if (byReportNo) {
      return byReportNo;
    }
  }

  return null;
};

const loadSourcePits = async ({ wellId, sourceReport }) => {
  const sourceReportId = toText(sourceReport?._id);

  if (sourceReportId) {
    const scopedPits = await Pit.find({
      wellId,
      reportId: sourceReportId,
    })
      .sort({ createdAt: 1, _id: 1 })
      .lean();

    if (scopedPits.length > 0) {
      return scopedPits;
    }
  }

  const legacyPits = await Pit.find(legacyPitScopeFilter(wellId))
    .sort({ createdAt: -1, _id: -1 })
    .lean();

  return dedupeLatestPits(legacyPits);
};

const loadSourcePumps = async ({ wellId, sourceReport }) => {
  const sourceReportId = toText(sourceReport?._id);

  if (sourceReportId) {
    const scopedPumps = await Pump.find({
      wellId,
      reportId: sourceReportId,
    })
      .sort({ rowNumber: 1, createdAt: 1, _id: 1 })
      .lean();

    if (scopedPumps.length > 0) {
      return scopedPumps;
    }
  }

  return Pump.find(legacyScopedFilter(wellId))
    .sort({ rowNumber: 1, createdAt: 1, _id: 1 })
    .lean();
};

const loadSourceNozzle = async ({ wellId, sourceReport }) => {
  const sourceReportId = toText(sourceReport?._id);

  if (sourceReportId) {
    const scopedNozzle = await Nozzle.findOne({
      wellId,
      reportId: sourceReportId,
    })
      .sort({ createdAt: -1, _id: -1 })
      .lean();

    if (scopedNozzle) {
      return scopedNozzle;
    }
  }

  return Nozzle.findOne(legacyScopedFilter(wellId))
    .sort({ createdAt: -1, _id: -1 })
    .lean();
};

const loadSourceShakers = async ({ wellId, sourceReport }) => {
  const sourceReportId = toText(sourceReport?._id);

  if (sourceReportId) {
    const scopedShakers = await Shaker.find({
      wellId,
      reportId: sourceReportId,
    })
      .sort({ createdAt: 1, _id: 1 })
      .lean();

    if (scopedShakers.length > 0) {
      return scopedShakers;
    }
  }

  return Shaker.find(legacyScopedFilter(wellId))
    .sort({ createdAt: 1, _id: 1 })
    .lean();
};

const loadSourceOtherSce = async ({ wellId, sourceReport }) => {
  const sourceReportId = toText(sourceReport?._id);

  if (sourceReportId) {
    const scopedOtherSce = await OtherSce.find({
      wellId,
      reportId: sourceReportId,
    })
      .sort({ createdAt: 1, _id: 1 })
      .lean();

    if (scopedOtherSce.length > 0) {
      return scopedOtherSce;
    }
  }

  return OtherSce.find(legacyScopedFilter(wellId))
    .sort({ createdAt: 1, _id: 1 })
    .lean();
};

const cloneReportSnapshots = async ({ sourceReport, targetReport }) => {
  const wellId = toText(targetReport?.wellId);
  const targetReportId = toText(targetReport?._id);

  if (!wellId || !targetReportId) {
    return;
  }

  const [
    sourceWellGeneral,
    sourcePits,
    sourcePumps,
    sourceNozzle,
    sourceShakers,
    sourceOtherSce,
  ] =
    await Promise.all([
    loadSourceWellGeneral({ wellId, sourceReport }),
    loadSourcePits({ wellId, sourceReport }),
    loadSourcePumps({ wellId, sourceReport }),
    loadSourceNozzle({ wellId, sourceReport }),
    loadSourceShakers({ wellId, sourceReport }),
    loadSourceOtherSce({ wellId, sourceReport }),
  ]);

  if (sourceWellGeneral) {
    const clonedWellGeneral = cleanClone(sourceWellGeneral);

    await WellGeneral.create({
      ...clonedWellGeneral,
      wellId,
      reportId: targetReportId,
      reportNo: toText(targetReport.reportNo),
      userReportNo:
        toText(targetReport.userReportNo) || toText(targetReport.reportNo),
      date: toText(targetReport.reportDate) || toText(clonedWellGeneral.date),
    });
  }

  if (sourcePits.length > 0) {
    const clonedPits = sourcePits.map((pit) => ({
      ...cleanClone(pit),
      wellId,
      reportId: targetReportId,
      isLocked: false,
    }));

    await Pit.insertMany(clonedPits);
  }

  if (sourcePumps.length > 0) {
    const clonedPumps = sourcePumps.map((pump) => ({
      ...cleanClone(pump),
      wellId,
      reportId: targetReportId,
      reportNo: toText(targetReport.reportNo),
    }));

    await Pump.insertMany(clonedPumps);
  }

  if (sourceNozzle) {
    await Nozzle.create({
      ...cleanClone(sourceNozzle),
      wellId,
      reportId: targetReportId,
      reportNo: toText(targetReport.reportNo),
    });
  }

  if (sourceShakers.length > 0) {
    await Shaker.insertMany(
      sourceShakers.map((shaker) => ({
        ...cleanClone(shaker),
        wellId,
        reportId: targetReportId,
        reportNo: toText(targetReport.reportNo),
      }))
    );
  }

  if (sourceOtherSce.length > 0) {
    await OtherSce.insertMany(
      sourceOtherSce.map((item) => ({
        ...cleanClone(item),
        wellId,
        reportId: targetReportId,
        reportNo: toText(targetReport.reportNo),
      }))
    );
  }
};

const rollbackReportArtifacts = async (report) => {
  if (!report?._id) {
    return;
  }

  const reportId = toText(report._id);
  const wellId = toText(report.wellId);

  await Promise.allSettled([
    Report.findByIdAndDelete(reportId),
    Pit.deleteMany({ wellId, reportId }),
    WellGeneral.deleteMany({ wellId, reportId }),
    Pump.deleteMany({ wellId, reportId }),
    Nozzle.deleteMany({ wellId, reportId }),
    Shaker.deleteMany({ wellId, reportId }),
    OtherSce.deleteMany({ wellId, reportId }),
  ]);
};

export const createReport = async (req, res) => {
  try {
    const wellId = toText(req.body.wellId);
    const wellCheck = await ensureWellExists(wellId);
    if (!wellCheck.ok) {
      return res.status(wellCheck.status).json({
        success: false,
        message: wellCheck.message,
      });
    }

    const reportNo =
      toText(req.body.reportNo) || (await nextReportNoForWell(wellId));
    const userReportNo = toText(req.body.userReportNo) || reportNo;
    const reportDate = toText(req.body.reportDate);
    const title = toText(req.body.title) || `Report ${reportNo}`;
    const notes = toText(req.body.notes);
    const recommendedTreatment = toText(req.body.recommendedTreatment);
    const remarks = toText(req.body.remarks);
    const recapRemarks = toText(req.body.recapRemarks);
    const internalNotes = toText(req.body.internalNotes);
    const remarksAttachment = sanitizeRemarksAttachment(req.body.remarksAttachment);
    const carryOverFromReportId = toText(req.body.carryOverFromReportId);
    let sourceReport = null;

    const existing = await Report.findOne({ wellId, reportNo }).lean();
    if (existing) {
      return res.status(409).json({
        success: false,
        message: `Report ${reportNo} already exists for this well`,
      });
    }

    if (carryOverFromReportId) {
      sourceReport = await findSourceReport(wellId, carryOverFromReportId);

      if (!sourceReport) {
        return res.status(404).json({
          success: false,
          message: "Carry-over source report not found for this well",
        });
      }
    }

    const pumpRateAndPressure = hasPumpRateAndPressureInput(
      req.body.pumpRateAndPressure
    )
      ? sanitizePumpRateAndPressure(req.body.pumpRateAndPressure)
      : sanitizePumpRateAndPressure(sourceReport?.pumpRateAndPressure);

    const report = await Report.create({
      wellId,
      reportNo,
      userReportNo,
      reportDate,
      title,
      notes,
      recommendedTreatment,
      remarks,
      recapRemarks,
      internalNotes,
      remarksAttachment,
      pumpRateAndPressure,
    });

    try {
      if (carryOverFromReportId) {
        await cloneReportSnapshots({
          sourceReport,
          targetReport: report.toObject(),
        });
      }
    } catch (cloneError) {
      await rollbackReportArtifacts(report);
      return res.status(500).json({
        success: false,
        message: "Failed to carry over report data",
        error: cloneError.message,
      });
    }

    return res.status(201).json({
      success: true,
      message: carryOverFromReportId
        ? "Report created and carried over successfully"
        : "Report created successfully",
      data: report,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to create report",
      error: error.message,
    });
  }
};

export const getReports = async (req, res) => {
  try {
    const wellId = toText(req.query.wellId);
    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const wellCheck = await ensureWellExists(wellId);
    if (!wellCheck.ok) {
      return res.status(wellCheck.status).json({
        success: false,
        message: wellCheck.message,
      });
    }

    const search = toText(req.query.search);
    const filter = { wellId };

    if (search) {
      const regex = { $regex: escapeRegex(search), $options: "i" };
      filter.$or = [
        { reportNo: regex },
        { userReportNo: regex },
        { reportDate: regex },
        { title: regex },
        { notes: regex },
        { recommendedTreatment: regex },
        { remarks: regex },
        { recapRemarks: regex },
        { internalNotes: regex },
      ];
    }

    const reports = await Report.find(filter).sort({ createdAt: -1 }).lean();

    return res.status(200).json({
      success: true,
      count: reports.length,
      data: reports,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch reports",
      error: error.message,
    });
  }
};

export const getReportManagerRows = async (req, res) => {
  try {
    const wellId = toText(req.query.wellId);
    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const wellCheck = await ensureWellExists(wellId);
    if (!wellCheck.ok) {
      return res.status(wellCheck.status).json({
        success: false,
        message: wellCheck.message,
      });
    }

    const reports = await Report.find({ wellId }).sort({ createdAt: -1 }).lean();
    if (reports.length === 0) {
      return res.status(200).json({
        success: true,
        count: 0,
        data: [],
      });
    }

    const reportIds = reports.map((report) => toText(report._id)).filter(Boolean);
    const reportNos = reports.map((report) => toText(report.reportNo)).filter(Boolean);

    const [wellGeneralRows, mudReportRows, inventoryRows, pitRows] =
      await Promise.all([
        WellGeneral.find({
          wellId,
          $or: [
            { reportId: { $in: reportIds } },
            { reportNo: { $in: reportNos } },
          ],
        }).lean(),
        MudReportState.find({
          wellId,
          reportId: { $in: reportIds },
        }).lean(),
        InventorySnapshot.find({
          wellId,
          reportId: { $in: reportIds },
        }).lean(),
        Pit.find({
          wellId,
          reportId: { $in: reportIds },
        }).lean(),
      ]);

    const wellGeneralByReportId = pickLatestByKey(
      wellGeneralRows,
      (item) => item.reportId
    );
    const wellGeneralByReportNo = pickLatestByKey(
      wellGeneralRows,
      (item) => item.reportNo
    );
    const mudReportByReportId = pickLatestByKey(
      mudReportRows,
      (item) => item.reportId
    );
    const inventoryByReportId = buildInventorySummaryByReportId(inventoryRows);
    const pitByReportId = buildPitSummaryByReportId(pitRows);

    const data = reports.map((report) => {
      const reportId = toText(report._id);
      const reportNo = toText(report.reportNo);
      const wellGeneral =
        wellGeneralByReportId.get(reportId) || wellGeneralByReportNo.get(reportNo);
      const mudReport = mudReportByReportId.get(reportId);
      const inventory = inventoryByReportId.get(reportId);
      const pit = pitByReportId.get(reportId);

      return {
        reportId,
        wellId: toText(report.wellId),
        reportNo,
        userReportNo: toText(report.userReportNo),
        reportDate: toText(report.reportDate),
        title: toText(report.title),
        notes: toText(report.notes),
        recommendedTreatment: toText(report.recommendedTreatment),
        remarks: toText(report.remarks),
        recapRemarks: toText(report.recapRemarks),
        internalNotes: toText(report.internalNotes),
        activity: toText(wellGeneral?.activity),
        interval: toText(wellGeneral?.interval),
        md: round2(wellGeneral?.md),
        mudType: firstMeaningfulText(mudReport?.fluidType, pit?.mudType),
        mw: round2(
          firstPositiveNumber(
            extractMudWeight(mudReport?.propertyTable),
            pit?.mw
          )
        ),
        dailyCost: round2(inventory?.dailyCost),
        cumulativeCost: round2(inventory?.cumulativeCost),
        createdAt: toText(report.createdAt),
      };
    });

    return res.status(200).json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch report manager rows",
      error: error.message,
    });
  }
};

export const getReportById = async (req, res) => {
  try {
    const { id } = req.params;
    const report = await Report.findById(id).lean();

    if (!report) {
      return res.status(404).json({
        success: false,
        message: "Report not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: report,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch report",
      error: error.message,
    });
  }
};

export const updateReport = async (req, res) => {
  try {
    const { id } = req.params;
    const report = await Report.findById(id);

    if (!report) {
      return res.status(404).json({
        success: false,
        message: "Report not found",
      });
    }

    const previousReportNo = toText(report.reportNo);

    const nextReportNo = toText(req.body.reportNo);
    if (nextReportNo && nextReportNo !== report.reportNo) {
      const duplicate = await Report.findOne({
        _id: { $ne: id },
        wellId: report.wellId,
        reportNo: nextReportNo,
      }).lean();

      if (duplicate) {
        return res.status(409).json({
          success: false,
          message: `Report ${nextReportNo} already exists for this well`,
        });
      }
      report.reportNo = nextReportNo;
    }

    if (req.body.userReportNo !== undefined) {
      report.userReportNo = toText(req.body.userReportNo);
    }
    if (req.body.reportDate !== undefined) {
      report.reportDate = toText(req.body.reportDate);
    }
    if (req.body.title !== undefined) {
      report.title = toText(req.body.title);
    }
    if (req.body.notes !== undefined) {
      report.notes = toText(req.body.notes);
    }
    if (req.body.recommendedTreatment !== undefined) {
      report.recommendedTreatment = toText(req.body.recommendedTreatment);
    }
    if (req.body.remarks !== undefined) {
      report.remarks = toText(req.body.remarks);
    }
    if (req.body.recapRemarks !== undefined) {
      report.recapRemarks = toText(req.body.recapRemarks);
    }
    if (req.body.internalNotes !== undefined) {
      report.internalNotes = toText(req.body.internalNotes);
    }
    if (req.body.remarksAttachment !== undefined) {
      report.remarksAttachment = sanitizeRemarksAttachment(
        req.body.remarksAttachment
      );
    }
    if (req.body.pumpRateAndPressure !== undefined) {
      report.pumpRateAndPressure = sanitizePumpRateAndPressure(
        req.body.pumpRateAndPressure
      );
    }

    await report.save();

    const wellId = toText(report.wellId);
    const reportId = toText(report._id);

    await WellGeneral.updateMany(
      {
        wellId,
        $or: [
          { reportId },
          {
            reportNo: previousReportNo,
            $or: [
              { reportId: { $exists: false } },
              { reportId: null },
              { reportId: "" },
            ],
          },
        ],
      },
      {
        $set: {
          reportId,
          reportNo: toText(report.reportNo),
          userReportNo:
            toText(report.userReportNo) || toText(report.reportNo),
          date: toText(report.reportDate),
        },
      }
    );

    await Promise.allSettled([
      Pump.updateMany(
        { wellId, reportId },
        { $set: { reportNo: toText(report.reportNo) } }
      ),
      Nozzle.updateMany(
        { wellId, reportId },
        { $set: { reportNo: toText(report.reportNo) } }
      ),
      Shaker.updateMany(
        { wellId, reportId },
        { $set: { reportNo: toText(report.reportNo) } }
      ),
      OtherSce.updateMany(
        { wellId, reportId },
        { $set: { reportNo: toText(report.reportNo) } }
      ),
    ]);

    return res.status(200).json({
      success: true,
      message: "Report updated successfully",
      data: report,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update report",
      error: error.message,
    });
  }
};

export const deleteReport = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await Report.findByIdAndDelete(id);

    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: "Report not found",
      });
    }

    const reportId = toText(deleted._id);
    const wellId = toText(deleted.wellId);

    await Promise.allSettled([
      Pit.deleteMany({ wellId, reportId }),
      WellGeneral.deleteMany({ wellId, reportId }),
      Pump.deleteMany({ wellId, reportId }),
      Nozzle.deleteMany({ wellId, reportId }),
      Shaker.deleteMany({ wellId, reportId }),
      OtherSce.deleteMany({ wellId, reportId }),
    ]);

    return res.status(200).json({
      success: true,
      message: "Report deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete report",
      error: error.message,
    });
  }
};
