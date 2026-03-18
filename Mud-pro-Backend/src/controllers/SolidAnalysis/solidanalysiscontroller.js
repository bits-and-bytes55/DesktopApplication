import SolidsAnalysis from "../../modules/SolidAnalysis/solidanalysismodel.js";

// ═══════════════════════════════════════════════════════════════════════════
// HELPER: pure calculation — no DB touch
// ═══════════════════════════════════════════════════════════════════════════
function computeSolidsAnalysis({ mudWeight, retortSolids, oilVol, waterVol, bariteLb, bentoniteLb, cacl2Pct, oilSG, hgsSG, lgsSG, fluidType }) {
  const MW = Number(mudWeight) || 0;
  const S = Number(retortSolids) || 0;
  const O = Number(oilVol) || 0;
  const W = Number(waterVol) || 0;
  const OSG = Number(oilSG) || 0.81;
  const HSG = Number(hgsSG) || 4.10;
  const LSG = Number(lgsSG) || 2.40;
  const saltPct = Number(cacl2Pct) || 0;
  const bentLb = Number(bentoniteLb) || 0;
  const isWBM = (fluidType === 'Water-based');

  if (MW <= 0) return null;

  const bariteSG = 4.2;
  const bentoniteSG = 2.65;
  const drillSolidsSG = 2.6;
  const bblFactor = 42;

  const totalMudMassLb = MW * bblFactor; // Total mass per bbl
  const totalSolidsLb = totalMudMassLb * (S / 100); // Total solids mass per bbl (from retort)

  // 1. Additive inputs (lb/bbl)
  const hgsLb = bariteLb;
  const bentLbActual = bentoniteLb;
  const lgsLbTotal = totalSolidsLb - hgsLb;
  const drillSolidsLb = lgsLbTotal - bentLbActual;

  // 2. Brine & Dissolved Solids logic
  let brineSG;
  if (isWBM) {
    brineSG = 1.0;
  } else {
    // Brine Density SG = 0.99707 + (0.007923 * saltPct) + (0.00004964 * saltPct^2)
    brineSG = 0.99707 + (0.007923 * saltPct) + (0.00004964 * Math.pow(saltPct, 2));
  }
  const dissolvedSolidsPct = (brineSG - 1) * 100;
  const correctedSolidsPct = S - dissolvedSolidsPct;

  // 3. Volumetric % Calculation (Relative to Total Mud Weight as per industry tutorial)
  const hgsPercent = (hgsLb / totalMudMassLb) * 100;
  const lgsPercent = (lgsLbTotal / totalMudMassLb) * 100;
  const bentPercent = (bentLbActual / totalMudMassLb) * 100;
  const drillSolidsPercent = (drillSolidsLb / totalMudMassLb) * 100;

  // 4. Average Solids SG (Mass-weighted formula from tutorial)
  // Formula: ((HGS_lb * 4.2) + (Bent_lb * 2.65) + (DS_lb * 2.6)) / TotalSolids_lb
  const avgSG = totalSolidsLb > 0
    ? ((hgsLb * bariteSG) + (bentLbActual * bentoniteSG) + (drillSolidsLb * drillSolidsSG)) / totalSolidsLb
    : 0;

  // 5. DS/Bent Ratio
  const dsBentRatio = bentLbActual > 0 ? drillSolidsLb / bentLbActual : 0;

  return {
    mudWeight: MW,
    retortSolids: S,
    bariteLb: hgsLb,
    bentoniteLb: bentLbActual,
    brineSG,
    hgsPercent,
    lgsPercent,
    lgsLb: lgsLbTotal,
    hgsLb: hgsLb,
    dissolvedSolids: dissolvedSolidsPct,
    correctedSolids: correctedSolidsPct,
    bentPercent,
    drillSolidsLb,
    drillSolidsPercent,
    dsBentRatio,
    avgSG,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/solids
// First-time create. Returns _id so Flutter can use PUT for future updates.
// Body: { reportId, sampleIndex, mudWeight, retortSolids, bariteLb, bentoniteLb, brineSG }
// ═══════════════════════════════════════════════════════════════════════════
export const createSolidsAnalysis = async (req, res) => {
  try {
    const computed = computeSolidsAnalysis(req.body);
    if (!computed) {
      return res.status(400).json({ success: false, message: "Mud Weight must be > 0" });
    }

    const record = await SolidsAnalysis.create({
      ...computed,
      reportId: req.body.reportId ?? null,
      sampleIndex: req.body.sampleIndex ?? 0,
    });

    return res.status(201).json({ success: true, message: "Solids Analysis created", data: record });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// PUT /api/solids/:id
// Update existing record in-place on every field change (debounced from Flutter).
// Recalculates all derived fields.
// ═══════════════════════════════════════════════════════════════════════════
export const updateSolidsAnalysis = async (req, res) => {
  try {
    const { id } = req.params;
    const computed = computeSolidsAnalysis(req.body);
    if (!computed) {
      return res.status(400).json({ success: false, message: "Mud Weight must be > 0" });
    }

    const updated = await SolidsAnalysis.findByIdAndUpdate(
      id,
      { $set: { ...computed, reportId: req.body.reportId ?? undefined, sampleIndex: req.body.sampleIndex ?? undefined } },
      { new: true, runValidators: true }
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
// GET /api/solids  →  latest record (or ?reportId=X to filter by report)
// GET /api/solids?limit=N  →  last N records
// ═══════════════════════════════════════════════════════════════════════════
export const getLatestSolidsAnalysis = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 1;
    const reportId = req.query.reportId || null;
    const query = reportId ? { reportId } : {};

    const records = await SolidsAnalysis.find(query).sort({ createdAt: -1 }).limit(limit).lean();

    if (!records || records.length === 0) {
      return res.status(404).json({ success: false, message: "No records found" });
    }

    return res.status(200).json({ success: true, count: records.length, data: limit === 1 ? records[0] : records });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/solids/calculate  — compute only, no DB write
// ═══════════════════════════════════════════════════════════════════════════
export const calculateOnly = async (req, res) => {
  try {
    const computed = computeSolidsAnalysis(req.body);
    if (!computed) {
      return res.status(400).json({ success: false, message: "Mud Weight must be > 0" });
    }
    return res.status(200).json({ success: true, message: "Calculated (not saved)", data: computed });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};