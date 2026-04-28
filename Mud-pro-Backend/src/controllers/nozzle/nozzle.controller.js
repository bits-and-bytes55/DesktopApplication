import mongoose from "mongoose";
import Nozzle from "../../modules/nozzle/nozzle.model.js";
import {
  readReportId,
  readReportNo,
  readWellId,
  toText,
} from "../../utils/reportScope.js";

const normalizeObjectId = (value) => {
  const textValue = toText(value);
  return mongoose.Types.ObjectId.isValid(textValue) ? textValue : "";
};

const cleanClone = (doc = {}) => {
  const clone = { ...doc };
  delete clone._id;
  delete clone.id;
  delete clone.__v;
  delete clone.createdAt;
  delete clone.updatedAt;
  delete clone.reportId;
  delete clone.reportNo;
  return clone;
};

const calculateNozzleArea = (size32) => {
  const diameter = (Number(size32) || 0) / 32;
  const rawArea = (Math.PI * Math.pow(diameter, 2)) / 4;
  return {
    diameter: +diameter.toFixed(4),
    area: +rawArea.toFixed(3),
  };
};

const processNozzles = (inputNozzles = []) => {
  const processedNozzles = [];
  let totalTFA = 0;

  inputNozzles.forEach((nz) => {
    const count = Number(nz?.count) || 0;
    const size32 = Number(nz?.size32) || 0;
    if (count <= 0 || size32 <= 0) {
      return;
    }

    const { diameter, area } = calculateNozzleArea(size32);
    totalTFA += area * count;
    processedNozzles.push({
      count,
      size32,
      diameterInch: diameter,
      area,
    });
  });

  return { processedNozzles, totalTFA: +totalTFA.toFixed(3) };
};

const hasBitInfoInput = (body = {}) =>
  Boolean(toText(body.bitType) || toText(body.bitModel));

const resolveScope = (req, existing = {}) => {
  const wellId = normalizeObjectId(readWellId(req) || existing.wellId);
  const reportId = normalizeObjectId(readReportId(req) || existing.reportId);
  const reportNo = reportId
    ? toText(readReportNo(req) || existing.reportNo)
    : "";

  return { wellId, reportId, reportNo };
};

const loadLegacyNozzle = async (wellId) =>
  Nozzle.findOne({
    ...(wellId ? { wellId } : {}),
    $or: [{ reportId: { $exists: false } }, { reportId: null }],
  })
    .sort({ createdAt: -1, _id: -1 })
    .lean();

const loadScopedNozzle = async (wellId, reportId) => {
  if (!wellId || !reportId) {
    return null;
  }

  return Nozzle.findOne({ wellId, reportId })
    .sort({ createdAt: -1, _id: -1 })
    .lean();
};

const loadDisplayNozzle = async ({ wellId, reportId }) => {
  if (wellId && reportId) {
    const scoped = await loadScopedNozzle(wellId, reportId);
    if (scoped) {
      return scoped;
    }
    return loadLegacyNozzle(wellId);
  }

  if (wellId) {
    return loadLegacyNozzle(wellId);
  }

  if (reportId) {
    return Nozzle.findOne({ reportId }).sort({ createdAt: -1, _id: -1 }).lean();
  }

  return Nozzle.findOne({}).sort({ createdAt: -1, _id: -1 }).lean();
};

const ensureReportNozzleCopy = async ({ wellId, reportId, reportNo }) => {
  if (!wellId || !reportId) {
    return null;
  }

  const scoped = await loadScopedNozzle(wellId, reportId);
  if (scoped) {
    return scoped;
  }

  const legacy = await loadLegacyNozzle(wellId);
  if (!legacy) {
    return null;
  }

  const created = await Nozzle.create({
    ...cleanClone(legacy),
    wellId,
    reportId,
    reportNo,
  });

  return created.toObject();
};

const buildPayload = ({
  existing = {},
  processedNozzles = [],
  totalTFA = 0,
  bitType,
  bitModel,
  wellId,
  reportId,
  reportNo,
}) => ({
  ...cleanClone(existing),
  wellId: wellId || null,
  reportId: reportId || null,
  reportNo: reportId ? reportNo : "",
  bitType: bitType !== undefined ? toText(bitType) : toText(existing.bitType),
  bitModel: bitModel !== undefined ? toText(bitModel) : toText(existing.bitModel),
  nozzles: processedNozzles,
  tfa: totalTFA,
});

export const createNozzle = async (req, res) => {
  try {
    const scope = resolveScope(req);
    if (req.body.wellId && !scope.wellId) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid wellId" });
    }

    const { processedNozzles, totalTFA } = processNozzles(req.body.nozzles);
    if (processedNozzles.length === 0 && !hasBitInfoInput(req.body)) {
      return res.status(400).json({
        success: false,
        message: "Nozzle data is required",
      });
    }

    if (scope.reportId) {
      const scopedExisting = await loadScopedNozzle(scope.wellId, scope.reportId);
      if (scopedExisting) {
        const updated = await Nozzle.findByIdAndUpdate(
          scopedExisting._id,
          buildPayload({
            existing: scopedExisting,
            processedNozzles,
            totalTFA,
            bitType: req.body.bitType,
            bitModel: req.body.bitModel,
            wellId: scope.wellId,
            reportId: scope.reportId,
            reportNo: scope.reportNo,
          }),
          { new: true, runValidators: true }
        );

        return res.status(200).json({ success: true, data: updated });
      }
    }

    const legacyExisting =
      scope.wellId && !scope.reportId ? await loadLegacyNozzle(scope.wellId) : null;
    if (legacyExisting) {
      const updated = await Nozzle.findByIdAndUpdate(
        legacyExisting._id,
        buildPayload({
          existing: legacyExisting,
          processedNozzles,
          totalTFA,
          bitType: req.body.bitType,
          bitModel: req.body.bitModel,
          wellId: scope.wellId,
          reportId: "",
          reportNo: "",
        }),
        { new: true, runValidators: true }
      );

      return res.status(200).json({ success: true, data: updated });
    }

    const nozzle = await Nozzle.create(
      buildPayload({
        processedNozzles,
        totalTFA,
        bitType: req.body.bitType,
        bitModel: req.body.bitModel,
        wellId: scope.wellId,
        reportId: scope.reportId,
        reportNo: scope.reportNo,
      })
    );

    return res.status(201).json({ success: true, data: nozzle });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

export const getNozzles = async (req, res) => {
  try {
    const nozzle = await loadDisplayNozzle(resolveScope(req));
    return res
      .status(200)
      .json({ success: true, data: nozzle ? [nozzle] : [] });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

export const updateNozzle = async (req, res) => {
  try {
    const { id } = req.params;
    const existing = await Nozzle.findById(id);

    if (!existing) {
      return res
        .status(404)
        .json({ success: false, message: "Nozzle not found" });
    }

    const scope = resolveScope(req, existing);
    const { processedNozzles, totalTFA } = processNozzles(req.body.nozzles);

    if (scope.reportId && toText(existing.reportId) !== scope.reportId) {
      const scopedCopy = await ensureReportNozzleCopy(scope);
      const targetId = scopedCopy?._id || scopedCopy?.id;
      const targetExisting = targetId
        ? await Nozzle.findById(targetId)
        : null;

      if (targetExisting) {
        const updated = await Nozzle.findByIdAndUpdate(
          targetExisting._id,
          buildPayload({
            existing: targetExisting.toObject(),
            processedNozzles,
            totalTFA,
            bitType: req.body.bitType,
            bitModel: req.body.bitModel,
            wellId: scope.wellId,
            reportId: scope.reportId,
            reportNo: scope.reportNo,
          }),
          { new: true, runValidators: true }
        );

        return res.status(200).json({ success: true, data: updated });
      }

      const created = await Nozzle.create(
        buildPayload({
          existing: existing.toObject(),
          processedNozzles,
          totalTFA,
          bitType: req.body.bitType,
          bitModel: req.body.bitModel,
          wellId: scope.wellId,
          reportId: scope.reportId,
          reportNo: scope.reportNo,
        })
      );

      return res.status(200).json({ success: true, data: created });
    }

    const updated = await Nozzle.findByIdAndUpdate(
      id,
      buildPayload({
        existing: existing.toObject(),
        processedNozzles,
        totalTFA,
        bitType: req.body.bitType,
        bitModel: req.body.bitModel,
        wellId: scope.wellId,
        reportId: scope.reportId,
        reportNo: scope.reportNo,
      }),
      { new: true, runValidators: true }
    );

    return res.status(200).json({ success: true, data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
