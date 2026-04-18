import EmptyFluidActiveSystem from "../../modules/emptyfluidactivesystem/EmptyFluidActiveSystem.js";
import { getWritablePits } from "../../utils/pitReportState.js";
import { buildScopedFilter, readReportId } from "../../utils/reportScope.js";

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
  let remaining = total;

  for (let i = 0; i < activePits.length; i++) {
    if (remaining <= 0) break;

    const pit = activePits[i];
    const pitsLeft = activePits.length - i;

    let deduct = round2(remaining / pitsLeft);
    if (deduct > toNumber(pit.volume)) {
      deduct = round2(toNumber(pit.volume));
    }

    pit.volume = round2(toNumber(pit.volume) - deduct);
    remaining = round2(remaining - deduct);

    await pit.save();
  }

  if (remaining > 0) {
    throw new Error("Unable to deduct full volume from active pits");
  }
};

const revertToActive = async (activePits, total) => {
  let remaining = total;

  for (let i = 0; i < activePits.length; i++) {
    const pit = activePits[i];
    const pitsLeft = activePits.length - i;

    const add = round2(remaining / pitsLeft);
    pit.volume = round2(toNumber(pit.volume) + add);

    remaining = round2(remaining - add);
    await pit.save();
  }
};

// ---------- CREATE ----------

export const createEmptyFluidActiveSystem = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const payloads = Array.isArray(req.body) ? req.body : [req.body];

    const created = [];

    for (const payload of payloads) {
      const { actionType, transfers = [], volume } = payload;

      const pits = await getPits(wellId, reportId);
      const activePits = getActivePits(pits);
      const storagePits = getStoragePits(pits);

      const totalActiveVol = round2(
        activePits.reduce((s, p) => s + toNumber(p.volume), 0)
      );

      // ---------- DUMP ----------
      if (actionType === "Dump") {
        const dumpVol = round2(toNumber(volume));

        if (dumpVol <= 0) throw new Error("Invalid dump volume");
        if (dumpVol > totalActiveVol)
          throw new Error("Dump exceeds active volume");

        await deductFromActive(activePits, dumpVol);

        const item = await EmptyFluidActiveSystem.create({
          wellId,
          reportId,
          actionType,
          pitName: "",
          volume: dumpVol,
          totalVolume: dumpVol,
        });

        created.push(item);
      }

      // ---------- TRANSFER ----------
      if (actionType === "Transfer to Storage") {
        const clean = transfers.map((t) => ({
          pitName: String(t.pitName).trim(),
          volume: round2(toNumber(t.volume)),
        }));

        const total = round2(clean.reduce((s, i) => s + i.volume, 0));

        if (total > totalActiveVol)
          throw new Error("Transfer exceeds active volume");

        // add to storage
        for (const t of clean) {
          const pit = storagePits.find((p) => p.pitName === t.pitName);
          if (!pit) throw new Error(`Storage pit ${t.pitName} not found`);

          pit.volume = round2(toNumber(pit.volume) + t.volume);
          await pit.save();
        }

        await deductFromActive(activePits, total);

        const items = await EmptyFluidActiveSystem.insertMany(
          clean.map((t) => ({
            wellId,
            reportId,
            actionType,
            pitName: t.pitName,
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
    buildScopedFilter(wellId, reportId)
  ).sort({
    createdAt: -1,
  });

  res.json({ success: true, count: data.length, data });
};

export const getEmptyFluidById = async (req, res) => {
  const wellId = getWellId(req);
  const reportId = readReportId(req);
  const { id } = req.params;

  const item = await EmptyFluidActiveSystem.findOne({
    _id: id,
    ...buildScopedFilter(wellId, reportId),
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
      ...buildScopedFilter(wellId, reportId),
    });

    if (!existing) throw new Error("Record not found");

    const pits = await getPits(wellId, reportId);
    const activePits = getActivePits(pits);
    const storagePits = getStoragePits(pits);

    // rollback old
    await revertToActive(activePits, toNumber(existing.totalVolume));

    if (existing.actionType === "Transfer to Storage") {
      const pit = storagePits.find((p) => p.pitName === existing.pitName);
      if (pit) {
        pit.volume = round2(toNumber(pit.volume) - existing.volume);
        await pit.save();
      }
    }

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
      ...buildScopedFilter(wellId, reportId),
    });

    if (!existing) throw new Error("Record not found");

    const pits = await getPits(wellId, reportId);
    const activePits = getActivePits(pits);
    const storagePits = getStoragePits(pits);

    // rollback
    await revertToActive(activePits, toNumber(existing.totalVolume));

    if (existing.actionType === "Transfer to Storage") {
      const pit = storagePits.find((p) => p.pitName === existing.pitName);
      if (pit) {
        pit.volume = round2(toNumber(pit.volume) - existing.volume);
        await pit.save();
      }
    }

    await EmptyFluidActiveSystem.deleteOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    res.json({ success: true, message: "Deleted successfully" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
