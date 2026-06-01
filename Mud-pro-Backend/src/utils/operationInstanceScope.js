export const readOperationInstanceKey = (req) =>
  String(req.query.operationInstanceKey ?? req.body?.operationInstanceKey ?? "")
    .trim();

export const operationInstanceFilter = (operationInstanceKey, legacyKey) => {
  const key = String(operationInstanceKey ?? "").trim();
  if (!key) return {};

  if (key === legacyKey) {
    return {
      $or: [
        { operationInstanceKey: key },
        { operationInstanceKey: { $exists: false } },
        { operationInstanceKey: null },
        { operationInstanceKey: "" },
      ],
    };
  }

  return { operationInstanceKey: key };
};

export const withOperationInstanceScope = (
  filter,
  operationInstanceKey,
  legacyKey
) => {
  const scoped = operationInstanceFilter(operationInstanceKey, legacyKey);
  if (Object.keys(scoped).length === 0) return filter;

  if (filter.$or && scoped.$or) {
    return { $and: [filter, scoped] };
  }

  return { ...filter, ...scoped };
};

export const operationInstancePayload = (req, existing = {}) =>
  String(
    req.body?.operationInstanceKey ??
      req.query.operationInstanceKey ??
      existing.operationInstanceKey ??
      ""
  ).trim();

export const recordMatchesOperationInstance = (
  record,
  operationInstanceKey,
  legacyKey
) => {
  const key = String(operationInstanceKey ?? "").trim();
  if (!key) return true;

  const recordKey = String(record?.operationInstanceKey ?? "").trim();
  if (key === legacyKey) {
    return recordKey === "" || recordKey === key;
  }

  return recordKey === key;
};
