import SolidsAnalysis from "../../modules/SolidAnalysis/solidanalysismodel.js";

// ═══════════════════════════════════════════════════════════════════════════
// PURE CALCULATION — Exact Excel DMR formulas
//
// Excel row references:
//   L25  = Mud Weight (ppg)
//   L44  = Total Solids % vol = 100-(Oil+Water)
//   L45  = Corrected Solids % vol
//   L46  = Oil % vol
//   L54  = CaCl2 % wt
//   L57  = LGS Density (SG)   ← from table row, default 2.6
//   L58  = HGS Density (SG)   ← from table row, default 4.2
//   L59  = Oil Density (SG)
//   L61  = Brine Density SG   = 0.99707 + 0.007923*CaCl2 + 0.00004964*CaCl2²
//   L62  = Brine % vol        (from Solid Analysis section)
//   L63  = LGS % = CorrSolids - HGS%
//   L65  = HGS % = ((AvgSG - LGS_SG)/(HGS_SG - LGS_SG)) * CorrSolids
//   L67  = Avg Solids Density  = (100*(MW/8.34) - Oil%*OilSG - BrineSG*Brine%) / CorrSolids%
//
// Formulas (from Excel):
//   BrineSG    = 0.99707 + 0.007923*CaCl2 + 0.00004964*CaCl2²
//   AvgSG      = (100*(MW/8.34) - Oil%*OilSG - BrineSG*Brine%) / CorrSolids%
//   HGS%       = ((AvgSG - LGS_SG) / (HGS_SG - LGS_SG)) * CorrSolids%
//   LGS%       = CorrSolids% - HGS%
//   LGS lb/bbl = 3.5 * LGS_SG * LGS%
//   HGS lb/bbl = 3.5 * HGS_SG * HGS%
// ═══════════════════════════════════════════════════════════════════════════

const SOLIDS_ANALYSIS_KEYS = [
  "mudWeight",
  "retortSolids",
  "bariteLb",
  "bentoniteLb",
  "brineSG",
  "brineDensityPpg",
  "brineVol",
  "oilSG",
  "hgsSG",
  "lgsSG",
  "isWeightedMud",
  "fluidType",
  "saltType",
  "totalSolids",
  "correctedSolids",
  "dissolvedSolids",
  "avgSG",
  "hgsPercent",
  "hgsLb",
  "lgsPercent",
  "lgsLb",
  "bentPercent",
  "drillSolidsPercent",
  "drillSolidsLb",
  "dsBentRatio",
  "obmChemicalsPercent",
  "obmChemicalsLb",
];

const toFiniteNumber = (value, fallback = 0) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const hasClientComputedSolids = (body = {}) =>
  ["correctedSolids", "avgSG", "hgsPercent", "hgsLb", "lgsPercent", "lgsLb"].every(
    (key) => body[key] !== undefined && body[key] !== null && body[key] !== "",
  );

const pickClientComputedSolids = (body = {}) => {
  const computed = {};
  for (const key of SOLIDS_ANALYSIS_KEYS) {
    if (body[key] !== undefined && body[key] !== null && body[key] !== "") {
      if (key === "isWeightedMud") {
        computed[key] = body[key] === true || body[key] === "true" || Number(body[key]) > 0;
      } else if (key === "fluidType" || key === "saltType") {
        computed[key] = String(body[key]);
      } else {
        computed[key] = toFiniteNumber(body[key]);
      }
    }
  }
  return computed;
};

function computeSolidsAnalysis({
  mudWeight,
  retortSolids,
  oilVol,
  waterVol,
  bariteLb,
  bentoniteLb,
  cacl2Pct,
  oilSG = 0.81,
  hgsSG = 4.20,
  lgsSG = 2.60,
  brineVolPct,
  brineDensityPpg,
  corrSolidsPct,
  fluidType = "Oil-based",
  saltType = "",
  isWeightedMud = false,
  mbt = 0,
  shaleCec = 15,
  bentCec = 65,
}) {
  const MW = toFiniteNumber(mudWeight);
  const RS = toFiniteNumber(retortSolids);
  const O = toFiniteNumber(oilVol);
  const W = toFiniteNumber(waterVol);
  const barite = toFiniteNumber(bariteLb);
  const bent = toFiniteNumber(bentoniteLb);
  const saltPct = toFiniteNumber(cacl2Pct);
  const OSG = toFiniteNumber(oilSG, 0.81);
  const HSG = toFiniteNumber(hgsSG, 4.20);
  const LSG = toFiniteNumber(lgsSG, 2.60);
  const fluid = String(fluidType || "");
  const isOilMud = /oil|synthetic/i.test(fluid);
  const weighted =
    isWeightedMud === true || isWeightedMud === "true" || Number(isWeightedMud) > 0;

  if (MW <= 0) return null;

  const brineSG = toFiniteNumber(brineDensityPpg) > 0
    ? toFiniteNumber(brineDensityPpg) / 8.345
    : saltPct > 0
      ? 0.99707 + (0.007923 * saltPct) + (0.00004964 * saltPct * saltPct)
      : 1;

  let brineVol;
  if (toFiniteNumber(brineVolPct) > 0) {
    brineVol = toFiniteNumber(brineVolPct);
  } else if (saltPct > 0 && W > 0 && brineSG > 0) {
    brineVol = W / ((1 - saltPct / 100) * brineSG);
  } else {
    brineVol = W;
  }

  const dissolvedSolids = Math.max(0, brineVol - W);
  const correctedSolids = Math.max(
    0,
    toFiniteNumber(corrSolidsPct) > 0 ? toFiniteNumber(corrSolidsPct) : RS - dissolvedSolids,
  );
  const totalSolids = RS > 0 ? RS : Math.max(0, 100 - (O + W));

  let hgsPercent = 0;
  let lgsPercent = correctedSolids;
  let avgSG = correctedSolids > 0 ? LSG : 0;
  if (weighted && HSG !== LSG && correctedSolids > 0) {
    const mudVolumeDensity = MW * 42 / 3.5;
    hgsPercent =
      (mudVolumeDensity - O * OSG - brineVol * brineSG - correctedSolids * LSG) /
      (HSG - LSG);
    lgsPercent = correctedSolids - hgsPercent;
    avgSG = (lgsPercent * LSG + hgsPercent * HSG) / correctedSolids;
  }

  const lgsLb = 3.5 * LSG * lgsPercent;
  const hgsLb = 3.5 * HSG * hgsPercent;
  let effectiveBent = bent;
  let drillSolidsLb = lgsLb - effectiveBent;

  if (!isOilMud && toFiniteNumber(mbt) > 0 && toFiniteNumber(bentCec) !== toFiniteNumber(shaleCec)) {
    effectiveBent =
      (toFiniteNumber(mbt) * 70 - lgsLb * toFiniteNumber(shaleCec)) /
      (toFiniteNumber(bentCec) - toFiniteNumber(shaleCec));
    drillSolidsLb = lgsLb - effectiveBent;
  }

  const bentPercent = LSG > 0 ? effectiveBent / (3.5 * LSG) : 0;
  const drillSolidsPercent = LSG > 0 ? drillSolidsLb / (3.5 * LSG) : 0;
  const dsBentRatio = effectiveBent !== 0 ? drillSolidsLb / effectiveBent : 0;
  const totalSolidsLb = MW * 42 * (totalSolids / 100);

  return {
    mudWeight: MW,
    retortSolids: RS,
    bariteLb: barite,
    bentoniteLb: effectiveBent,
    brineSG,
    brineDensityPpg: brineSG * 8.345,
    brineVol,
    oilSG: OSG,
    hgsSG: HSG,
    lgsSG: LSG,
    isWeightedMud: weighted,
    fluidType: fluid,
    saltType: String(saltType || ""),
    totalSolids,
    totalSolidsLb,
    correctedSolids,
    dissolvedSolids,
    avgSG,
    hgsPercent,
    hgsLb,
    lgsPercent,
    lgsLb,
    bentPercent,
    drillSolidsPercent,
    drillSolidsLb,
    dsBentRatio,
    obmChemicalsPercent: 0,
    obmChemicalsLb: 0,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/solids
// ═══════════════════════════════════════════════════════════════════════════
export const createSolidsAnalysis = async (req, res) => {
  try {
    const computed = hasClientComputedSolids(req.body)
      ? pickClientComputedSolids(req.body)
      : computeSolidsAnalysis(req.body);
    if (!computed) {
      return res.status(400).json({ success: false, message: "Mud Weight must be > 0" });
    }
    const record = await SolidsAnalysis.create({
      ...computed,
      wellId:      req.body.wellId      ?? "",
      reportId:    req.body.reportId    ?? null,
      sampleIndex: req.body.sampleIndex ?? 0,
    });
    return res.status(201).json({ success: true, message: "Solids Analysis created", data: record });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// PUT /api/solids/:id
// ═══════════════════════════════════════════════════════════════════════════
export const updateSolidsAnalysis = async (req, res) => {
  try {
    const { id } = req.params;
    const wellId = String(req.query.wellId ?? req.body.wellId ?? "").trim();
    const reportId = String(req.query.reportId ?? req.body.reportId ?? "").trim();
    const computed = hasClientComputedSolids(req.body)
      ? pickClientComputedSolids(req.body)
      : computeSolidsAnalysis(req.body);
    if (!computed) {
      return res.status(400).json({ success: false, message: "Mud Weight must be > 0" });
    }
    const updated = await SolidsAnalysis.findOneAndUpdate(
      {
        _id: id,
        ...(wellId ? { wellId } : {}),
        ...(reportId ? { reportId } : {}),
      },
      { $set: { ...computed, wellId: req.body.wellId ?? undefined, reportId: req.body.reportId ?? undefined, sampleIndex: req.body.sampleIndex ?? undefined } },
      { returnDocument: "after", runValidators: true }
    );
    if (!updated) {
      return res.status(404).json({ success: false, message: `No record found with id: ${id}` });
    }
    return res.status(200).json({ success: true, message: "Solids Analysis updated", data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// GET /api/solids
// ═══════════════════════════════════════════════════════════════════════════
export const getLatestSolidsAnalysis = async (req, res) => {
  try {
    const limit    = parseInt(req.query.limit) || 1;
    const reportId = req.query.reportId || null;
    const wellId   = req.query.wellId || null;
    const query    = {
      ...(wellId ? { wellId } : {}),
      ...(reportId ? { reportId } : {}),
    };
    const records  = await SolidsAnalysis.find(query).sort({ createdAt: -1 }).limit(limit).lean();
    if (!records || records.length === 0) {
      return res.status(404).json({ success: false, message: "No records found" });
    }
    return res.status(200).json({ success: true, count: records.length, data: limit === 1 ? records[0] : records });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/solids/calculate
// ═══════════════════════════════════════════════════════════════════════════
export const calculateOnly = async (req, res) => {
  try {
    const computed = hasClientComputedSolids(req.body)
      ? pickClientComputedSolids(req.body)
      : computeSolidsAnalysis(req.body);
    if (!computed) {
      return res.status(400).json({ success: false, message: "Mud Weight must be > 0" });
    }
    return res.status(200).json({ success: true, message: "Calculated (not saved)", data: computed });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
