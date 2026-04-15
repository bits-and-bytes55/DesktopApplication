export const toText = (value) => String(value ?? "").trim();

export const readReportId = (req) =>
  toText(req.query.reportId ?? req.body?.reportId);

export const readReportNo = (req) =>
  toText(req.query.reportNo ?? req.body?.reportNo);

export const readWellId = (req) => toText(req.query.wellId ?? req.body?.wellId);

export const legacyReportScope = (field = "reportId") => ({
  $or: [{ [field]: { $exists: false } }, { [field]: null }, { [field]: "" }],
});

export const buildScopedFilter = (wellId, reportId, extra = {}) => {
  if (reportId) {
    return { wellId, reportId, ...extra };
  }

  return { wellId, ...extra, ...legacyReportScope() };
};
