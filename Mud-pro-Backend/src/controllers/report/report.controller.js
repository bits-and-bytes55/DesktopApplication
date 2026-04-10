import mongoose from "mongoose";
import Report from "../../modules/report/report.model.js";
import Well from "../../modules/well/well.model.js";
import WellGeneral from "../../modules/wellGeneral/wellGeneralModel.js";
import Pit from "../../modules/pit/pit.model.js";

const toText = (value) => String(value ?? "").trim();

const escapeRegex = (value) =>
  String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

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

const cloneReportSnapshots = async ({ sourceReport, targetReport }) => {
  const wellId = toText(targetReport?.wellId);
  const targetReportId = toText(targetReport?._id);

  if (!wellId || !targetReportId) {
    return;
  }

  const [sourceWellGeneral, sourcePits] = await Promise.all([
    loadSourceWellGeneral({ wellId, sourceReport }),
    loadSourcePits({ wellId, sourceReport }),
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
    const carryOverFromReportId = toText(req.body.carryOverFromReportId);

    const existing = await Report.findOne({ wellId, reportNo }).lean();
    if (existing) {
      return res.status(409).json({
        success: false,
        message: `Report ${reportNo} already exists for this well`,
      });
    }

    const report = await Report.create({
      wellId,
      reportNo,
      userReportNo,
      reportDate,
      title,
      notes,
    });

    try {
      if (carryOverFromReportId) {
        const sourceReport = await findSourceReport(wellId, carryOverFromReportId);

        if (!sourceReport) {
          await rollbackReportArtifacts(report);
          return res.status(404).json({
            success: false,
            message: "Carry-over source report not found for this well",
          });
        }

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
