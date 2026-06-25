import EmptyFluidActiveSystem from "../../modules/emptyfluidactivesystem/EmptyFluidActiveSystem.js";
import { getWritablePits } from "../../utils/pitReportState.js";
import { buildScopedFilter, readReportId } from "../../utils/reportScope.js";
import {
  operationInstancePayload,
  readOperationInstanceKey,
  withOperationInstanceScope,
} from "../../utils/operationInstanceScope.js";

const LEGACY_OPERATION_INSTANCE_KEY = "emptyActiveSystem::legacy0";

const toNumber = (value) => {
  if (!value) return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));
const getWellId = (req) => String(req.params.wellId || "").trim();

const getPits = async (wellId, reportId) => {
  const pits = await getWritablePits({ wellId, reportId });
  if (!pits.length) throw new Error("No pits found for this wellId");
  return pits;
};

const getActivePits = (pits) => {
  const active = pits.filter((p) => p.initialActive);
  if (!active.length) throw new Error("No active pits found");
  return active;
};

const getStoragePits = (pits) => pits.filter((p) => !p.initialActive);

// ---------- COMMON LOGIC ----------

const deductFromActive = async (activePits, total) => {
  return;
};

const revertToActive = async (activePits, total) => {
  return;
};

// ---------- CREATE ----------

export const createEmptyFluidActiveSystem = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const requestOperationInstanceKey = operationInstancePayload(req);
    const payloads = Array.isArray(req.body) ? req.body : [req.body];

    const created = [];
    const clearedInstanceKeys = new Set();

    for (const payload of payloads) {
      const { actionType, transfers = [], volume } = payload;
      const operationInstanceKey = String(
        payload.operationInstanceKey || requestOperationInstanceKey
      ).trim();

      if (operationInstanceKey && !clearedInstanceKeys.has(operationInstanceKey)) {
        await EmptyFluidActiveSystem.deleteMany(
          buildScopedFilter(wellId, reportId, { operationInstanceKey })
        );
        clearedInstanceKeys.add(operationInstanceKey);
      }

      // ---------- DUMP ----------
      if (actionType === "Dump") {
        const dumpVol = round2(toNumber(volume));

        const item = await EmptyFluidActiveSystem.create({
          wellId,
          reportId,
          operationInstanceKey,
          actionType,
          pitName: "",
          volume: dumpVol,
          totalVolume: dumpVol,
        });

        created.push(item);
      }

      // ---------- TRANSFER ----------
      if (actionType === "Transfer to Storage") {
        const clean = transfers.map((t, index) => ({
          pitName: String(t.pitName).trim(),
          rowNumber: Math.max(
            1,
            Math.trunc(toNumber(t.rowNumber)) || index + 1
          ),
          volume: round2(toNumber(t.volume)),
        }));

        const total = round2(clean.reduce((s, i) => s + i.volume, 0));

        const items = await EmptyFluidActiveSystem.insertMany(
          clean.map((t) => ({
            wellId,
            reportId,
            operationInstanceKey,
            actionType,
            pitName: t.pitName,
            rowNumber: t.rowNumber,
            volume: t.volume,
            totalVolume: total,
          }))
        );

        created.push(...items);
      }
    }

    return res.status(201).json({
      success: true,
      count: created.length,
      data: created,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ---------- GET ----------

export const getEmptyFluidList = async (req, res) => {
  const wellId = getWellId(req);
  const reportId = readReportId(req);

  const data = await EmptyFluidActiveSystem.find(
    withOperationInstanceScope(
      buildScopedFilter(wellId, reportId),
      readOperationInstanceKey(req),
      LEGACY_OPERATION_INSTANCE_KEY
    )
  ).sort({
    rowNumber: 1,
    createdAt: 1,
  });

  res.json({ success: true, count: data.length, data });
};

export const getEmptyFluidById = async (req, res) => {
  const wellId = getWellId(req);
  const reportId = readReportId(req);
  const { id } = req.params;

  const item = await EmptyFluidActiveSystem.findOne({
    _id: id,
    ...withOperationInstanceScope(
      buildScopedFilter(wellId, reportId),
      readOperationInstanceKey(req),
      LEGACY_OPERATION_INSTANCE_KEY
    ),
  });

  if (!item) {
    return res.status(404).json({ success: false, message: "Not found" });
  }

  res.json({ success: true, data: item });
};

// ---------- UPDATE ----------

export const updateEmptyFluid = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const { id } = req.params;

    const existing = await EmptyFluidActiveSystem.findOne({
      _id: id,
      ...withOperationInstanceScope(
        buildScopedFilter(wellId, reportId),
        readOperationInstanceKey(req),
        LEGACY_OPERATION_INSTANCE_KEY
      ),
    });

    if (!existing) throw new Error("Record not found");

    // apply new
    req.body.actionType = req.body.actionType || existing.actionType;

    return createEmptyFluidActiveSystem(req, res);
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ---------- DELETE ----------

export const deleteEmptyFluid = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const { id } = req.params;

    const existing = await EmptyFluidActiveSystem.findOne({
      _id: id,
      ...withOperationInstanceScope(
        buildScopedFilter(wellId, reportId),
        readOperationInstanceKey(req),
        LEGACY_OPERATION_INSTANCE_KEY
      ),
    });

    if (!existing) throw new Error("Record not found");

    await EmptyFluidActiveSystem.deleteOne({
      _id: id,
      ...withOperationInstanceScope(
        buildScopedFilter(wellId, reportId),
        readOperationInstanceKey(req),
        LEGACY_OPERATION_INSTANCE_KEY
      ),
    });

    res.json({ success: true, message: "Empty Active System deleted successfully" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
