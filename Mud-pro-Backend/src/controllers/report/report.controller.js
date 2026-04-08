import mongoose from "mongoose";
import Report from "../../modules/report/report.model.js";
import Well from "../../modules/well/well.model.js";

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

    const reportNo = toText(req.body.reportNo) || (await nextReportNoForWell(wellId));
    const userReportNo = toText(req.body.userReportNo) || reportNo;
    const reportDate = toText(req.body.reportDate);
    const title = toText(req.body.title) || `Report ${reportNo}`;
    const notes = toText(req.body.notes);

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

    return res.status(201).json({
      success: true,
      message: "Report created successfully",
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
