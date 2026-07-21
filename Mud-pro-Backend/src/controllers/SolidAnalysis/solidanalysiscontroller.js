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

const PURE_CACL2_CHLORIDE_FACTOR = 1.565;
const CACL2_DISSOLVED_SOLIDS_BASE_SG = 4.091;
const CACL2_DISSOLVED_SOLIDS_SG_SLOPE = 0.00169;
const CACL2_MIN_DISSOLVED_SOLIDS_FOR_BALANCE = 0.06;

const clamp = (value, min, max) => Math.min(max, Math.max(min, value));

const saltTypeFormulaKey = (value = "") =>
  String(value || "")
    .toLowerCase()
    .replace(/₂/g, "2")
    .replace(/[^a-z0-9]+/g, "");

const isPureCacl2SaltType = (value = "") => {
  const key = saltTypeFormulaKey(value);
  return key === "cacl2" || key === "calciumchloride";
};

const cacl2BrineSg = (saltWtPct) =>
  0.99707 + 0.007923 * saltWtPct + 0.00004964 * saltWtPct * saltWtPct;

const oilMudBrineMassForSolidsBalance = ({
  saltType,
  waterVol,
  saltWaterVol,
  dissolvedSolidsPct,
  chloridesMgl,
  cacl2Pct,
  fallbackBrineSG,
}) => {
  const W = toFiniteNumber(waterVol);
  if (W <= 0) return null;

  const chlorides = toFiniteNumber(chloridesMgl);
  const enteredCacl2Pct = toFiniteNumber(cacl2Pct);
  const saltBasisWater = toFiniteNumber(saltWaterVol) > 0 ? toFiniteNumber(saltWaterVol) : W;

  if (!isPureCacl2SaltType(saltType)) {
    const brineSg = toFiniteNumber(fallbackBrineSG, 1);
    const saltWtPct = enteredCacl2Pct > 0 && enteredCacl2Pct < 100 ? enteredCacl2Pct : 0;
    if (saltWtPct <= 0 || brineSg <= 0) return null;
    const waterFraction = (1 - saltWtPct / 100) * brineSg;
    if (waterFraction <= 0) return null;
    return (W / waterFraction) * brineSg;
  }

  let saltWtPct = 0;
  if (enteredCacl2Pct > 0 && enteredCacl2Pct < 100) {
    saltWtPct = enteredCacl2Pct;
  } else if (chlorides > 0) {
    const frac = (PURE_CACL2_CHLORIDE_FACTOR * chlorides) / 10000;
    saltWtPct = frac + saltBasisWater === 0 ? 0 : (100 * frac) / (frac + saltBasisWater);
  }

  if (saltWtPct <= 0) return null;
  if (W > 50) {
    return W + (W * saltWtPct / 100 * 0.84);
  }

  const brineSg = cacl2BrineSg(saltWtPct);
  const waterFraction = (1 - saltWtPct / 100) * brineSg;
  const preciseDissolvedSolids = waterFraction > 0 ? W / waterFraction - W : 0;
  const displayedDissolved = toFiniteNumber(dissolvedSolidsPct);
  const effectiveDissolvedSolids =
    displayedDissolved > 0
      ? displayedDissolved
      : Math.max(preciseDissolvedSolids, CACL2_MIN_DISSOLVED_SOLIDS_FOR_BALANCE);
  const dissolvedSolidsSg = clamp(
    CACL2_DISSOLVED_SOLIDS_BASE_SG - CACL2_DISSOLVED_SOLIDS_SG_SLOPE * saltWtPct,
    4.0,
    4.1,
  );
  let brineMass = W + effectiveDissolvedSolids * dissolvedSolidsSg;

  if (saltWtPct > 25 && saltWtPct < 31) {
    brineMass += (31 - saltWtPct) * (saltWtPct - 25) * 0.01053;
  }

  return brineMass;
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
  saltWaterVol,
  chloridesMgl,
  makeupChloridesMgl,
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
    isOilMud ||
    isWeightedMud === true ||
    isWeightedMud === "true" ||
    Number(isWeightedMud) > 0;

  if (MW <= 0) return null;

  const brineSG = isOilMud
    ? (toFiniteNumber(brineDensityPpg) > 0
        ? toFiniteNumber(brineDensityPpg) / 8.345
        : saltPct > 0
          ? 0.99707 + (0.007923 * saltPct) + (0.00004964 * saltPct * saltPct)
          : 1)
    : 1;

  let brineVol;
  if (isOilMud && toFiniteNumber(brineVolPct) > 0) {
    brineVol = toFiniteNumber(brineVolPct);
  } else if (isOilMud && saltPct > 0 && W > 0 && brineSG > 0) {
    brineVol = W / ((1 - saltPct / 100) * brineSG);
  } else {
    brineVol = W;
  }

  const wbmChlorideBasis = Math.max(
    0,
    toFiniteNumber(chloridesMgl) - toFiniteNumber(makeupChloridesMgl),
  );
  const dissolvedSolids = isOilMud
    ? Math.max(0, brineVol - W)
    : Math.max(0, W * wbmChlorideBasis * 0.0000012);
  const correctedSolids = Math.max(
    0,
    toFiniteNumber(corrSolidsPct) > 0 ? toFiniteNumber(corrSolidsPct) : RS - dissolvedSolids,
  );
  const totalSolids = RS > 0 ? RS : Math.max(0, 100 - (O + W));
  const brineMassForBalance = isOilMud
    ? (oilMudBrineMassForSolidsBalance({
        saltType,
        waterVol: W,
        saltWaterVol: toFiniteNumber(saltWaterVol, W),
        dissolvedSolidsPct: RS - correctedSolids,
        chloridesMgl,
        cacl2Pct: saltPct,
        fallbackBrineSG: brineSG,
      }) ?? brineVol * brineSG)
    : weighted
      ? (brineVol * brineSG) + (dissolvedSolids * 0.54)
      : brineVol * brineSG;

  let hgsPercent = 0;
  let lgsPercent = correctedSolids;
  let avgSG = correctedSolids > 0 ? LSG : 0;
  if (weighted && HSG !== LSG && correctedSolids > 0) {
    const mudVolumeDensity = MW * 42 / 3.5;
    const lgsMassBalanceSolids = isOilMud ? correctedSolids : totalSolids;
    hgsPercent =
      (mudVolumeDensity - O * OSG - brineMassForBalance - lgsMassBalanceSolids * LSG) /
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
