import WellGeneral from "../../modules/wellGeneral/wellGeneralModel.js";

const getWellId = (req) => String(req.params.wellId || "").trim();
const getReportId = (req) =>
  String(req.query.reportId ?? req.body?.reportId ?? "").trim();
const getReportNo = (req) =>
  String(req.query.reportNo ?? req.body?.reportNo ?? "").trim();

const toText = (value) => String(value ?? "").trim();

const upsertScopeFilter = ({ wellId, reportId, reportNo, recordId }) => {
  if (reportId) {
    return { wellId, reportId };
  }

  if (reportNo) {
    return { wellId, reportNo };
  }

  if (recordId) {
    return { _id: recordId, wellId };
  }

  return null;
};

// Create / upsert
export const createWellGeneral = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = getReportId(req);
    const reportNo = getReportNo(req);
    const recordId = toText(req.body.recordId);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const filter = upsertScopeFilter({ wellId, reportId, reportNo, recordId });
    let data = null;

    if (filter) {
      data = await WellGeneral.findOne(filter).sort({ createdAt: -1, _id: -1 });
    }

    if (data) {
      Object.assign(data, {
        ...req.body,
        wellId,
        reportId: reportId || data.reportId || "",
        reportNo: reportNo || toText(req.body.reportNo) || data.reportNo || "",
      });
      await data.save();

      return res.status(200).json({
        success: true,
        message: "Well General updated",
        data,
      });
    }

    data = await WellGeneral.create({
      ...req.body,
      wellId,
      reportId,
      reportNo: reportNo || toText(req.body.reportNo),
    });

    res.status(201).json({
      success: true,
      message: "Well General created",
      data,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Get all by wellId, optionally scoped by reportId/reportNo
export const getWellGenerals = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = getReportId(req);
    const reportNo = getReportNo(req);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const filter = { wellId };
    if (reportId) {
      filter.reportId = reportId;
    } else if (reportNo) {
      filter.reportNo = reportNo;
    }

    const data = await WellGeneral.find(filter).sort({ createdAt: -1, _id: -1 });

    res.status(200).json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const getWellGeneralById = async (req, res) => {
  try {
    const wellId = getWellId(req);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const data = await WellGeneral.findOne({
      _id: req.params.id,
      wellId,
    });

    if (!data) {
      return res.status(404).json({
        success: false,
        message: "Not found",
      });
    }

    res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const updateWellGeneral = async (req, res) => {
  try {
    const wellId = getWellId(req);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const data = await WellGeneral.findOneAndUpdate(
      {
        _id: req.params.id,
        wellId,
      },
      {
        ...req.body,
        wellId,
        ...(req.body.reportId !== undefined && {
          reportId: toText(req.body.reportId),
        }),
        ...(req.body.reportNo !== undefined && {
          reportNo: toText(req.body.reportNo),
        }),
      },
      { new: true }
    );

    if (!data) {
      return res.status(404).json({
        success: false,
        message: "Not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Updated",
      data,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const deleteWellGeneral = async (req, res) => {
  try {
    const wellId = getWellId(req);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const data = await WellGeneral.findOneAndDelete({
      _id: req.params.id,
      wellId,
    });

    if (!data) {
      return res.status(404).json({
        success: false,
        message: "Not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Deleted",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
