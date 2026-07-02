import WellGeneral from "../../modules/wellGeneral/wellGeneralModel.js";

const getWellId = (req) => String(req.params.wellId || "").trim();
const getReportId = (req) =>
  String(req.query.reportId ?? req.body?.reportId ?? "").trim();
const getReportNo = (req) =>
  String(req.query.reportNo ?? req.body?.reportNo ?? "").trim();

const toText = (value) => String(value ?? "").trim();
const toNumber = (value) => {
  const parsed = Number(String(value ?? "").replace(/,/g, "").trim());
  return Number.isFinite(parsed) ? parsed : 0;
};

const normalizeTimeDistributionRows = (rows) => {
  if (!Array.isArray(rows)) return rows;

  return rows
    .filter((row) => row && typeof row === "object")
    .map((row) => {
      const description =
        toText(row.description) || toText(row.activity) || toText(row.name);
      const hours = toNumber(row.hours ?? row.time ?? row.value);
      return { description, hours };
    })
    .filter((row) => row.description || row.hours !== 0);
};

const normalizeWellGeneralPayload = (body = {}) => {
  const payload = { ...body };
  if (Array.isArray(payload.timeDistributionRows)) {
    payload.timeDistributionRows = normalizeTimeDistributionRows(
      payload.timeDistributionRows
    );
  }
  return payload;
};

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
    const payload = normalizeWellGeneralPayload(req.body);
    const recordId = toText(payload.recordId);

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
        ...payload,
        wellId,
        reportId: reportId || data.reportId || "",
        reportNo: reportNo || toText(payload.reportNo) || data.reportNo || "",
      });
      await data.save();

      return res.status(200).json({
        success: true,
        message: "Well General updated",
        data,
      });
    }

    data = await WellGeneral.create({
      ...payload,
      wellId,
      reportId,
      reportNo: reportNo || toText(payload.reportNo),
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
    const reportId = getReportId(req);
    const payload = normalizeWellGeneralPayload(req.body);

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
        ...(reportId ? { reportId } : {}),
      },
      {
        ...payload,
        wellId,
        ...(payload.reportId !== undefined || reportId
          ? { reportId: toText(payload.reportId ?? reportId) }
          : {}),
        ...(payload.reportNo !== undefined && {
          reportNo: toText(payload.reportNo),
        }),
      },
      { returnDocument: "after" }
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
    const reportId = getReportId(req);

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const data = await WellGeneral.findOneAndDelete({
      _id: req.params.id,
      wellId,
      ...(reportId ? { reportId } : {}),
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
