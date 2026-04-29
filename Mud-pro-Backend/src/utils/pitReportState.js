import Pit from "../modules/pit/pit.model.js";
import { legacyReportScope, toText } from "./reportScope.js";

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

const mergeScopedWithLegacy = (scopedItems = [], legacyItems = []) => {
  const merged = new Map();

  for (const item of dedupeLatestPits(legacyItems)) {
    const key = toText(item.pitName).toLowerCase();
    if (!key) continue;
    merged.set(key, item);
  }

  for (const item of sortByCreatedAtAsc(scopedItems)) {
    const key = toText(item.pitName).toLowerCase();
    if (!key) continue;
    merged.set(key, item);
  }

  return sortByCreatedAtAsc(Array.from(merged.values()));
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

const legacyPitFilter = (wellId, extra = {}) => ({
  wellId,
  ...extra,
  ...legacyReportScope(),
});

export const loadMergedPits = async ({ wellId, reportId, initialActive }) => {
  const scopedExtra =
    initialActive !== undefined ? { initialActive } : {};

  if (reportId) {
    return Pit.find({
      wellId,
      reportId,
      ...scopedExtra,
    }).sort({ createdAt: 1, _id: 1 });
  }

  return Pit.find({ wellId, ...scopedExtra }).sort({ createdAt: 1, _id: 1 });
};

export const ensureWritablePit = async (pit, reportId) => {
  if (!pit || !reportId) {
    return pit;
  }

  if (toText(pit.reportId) === reportId) {
    return pit;
  }

  const wellId = toText(pit.wellId);
  const pitName = toText(pit.pitName);

  let scopedPit = await Pit.findOne({
    wellId,
    reportId,
    pitName,
  }).sort({ createdAt: -1, _id: -1 });

  if (scopedPit) {
    return scopedPit;
  }

  const source = typeof pit.toObject === "function" ? pit.toObject() : pit;
  scopedPit = await Pit.create({
    ...cleanClone(source),
    wellId,
    reportId,
    pitName,
    isLocked: false,
  });

  return scopedPit;
};

export const getWritablePits = async ({ wellId, reportId, initialActive }) => {
  const pits = await loadMergedPits({ wellId, reportId, initialActive });

  if (!reportId) {
    return pits;
  }

  const writable = [];
  for (const pit of pits) {
    writable.push(await ensureWritablePit(pit, reportId));
  }

  return writable;
};

export const findWritablePitByName = async ({
  wellId,
  reportId,
  pitName,
  initialActive,
}) => {
  const normalizedName = toText(pitName).toLowerCase();
  if (!normalizedName) return null;

  const pits = await loadMergedPits({ wellId, reportId, initialActive });
  const found = pits.find(
    (pit) => toText(pit.pitName).toLowerCase() === normalizedName
  );

  if (!found) {
    return null;
  }

  return ensureWritablePit(found, reportId);
};
