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

  let brineSG, brineVol, avgSG, dissolvedSolids, correctedSolids;
  const waterDensity = 0.99707; // Base density factor used in Excel for precise volume/mass conversion

  if (isWBM) {
    // ── Water-Based Mud formulas (Refined) ────────────────────────────────
    // Brine Density (SG) for WBM usually 1.0 (fresh) unless salt is added
    brineSG = 1.0;
    
    // Brine % vol = (Water * 100) / (BrineSG * (100 - CaCl2%) * waterDensity)
    // In Excel: =IFERROR((100*Water)/(BrineSG*(100-SaltPct)*0.99707),"")
    brineVol = (100 * W) / (brineSG * (100 - saltPct) * waterDensity);

    // dissolvedSolids = 0 for simple WBM
    dissolvedSolids = 0;

    // correctedSolids = retortSolids
    correctedSolids = S;

    // avgSG = ( (100*(MW/8.34)) - (Oil*OilSG) - (BrineSG*BrineVol*waterDensity) ) / Solids
    // Note: Excel formula L65 includes the oil term for WBM avgSG calculation
    avgSG = S > 0 ? ((100 * (MW / 8.34)) - (O * OSG) - (brineSG * brineVol * waterDensity)) / S : 0;

  } else {
    // ── Oil-Based Mud formulas (Original + Density Correction) ────────────
    brineSG = 0.99707 + (0.007923 * saltPct) + (0.00004964 * Math.pow(saltPct, 2));

    // Brine % vol
    brineVol = (brineSG > 0 && (100 - saltPct) > 0)
      ? (100 * W) / (brineSG * (100 - saltPct) * waterDensity)
      : W;

    // Average Solids SG
    avgSG = S > 0
      ? ((100 * (MW / 8.34)) - (O * OSG) - (brineSG * brineVol * waterDensity)) / S
      : 0;

    dissolvedSolids = (brineSG - 1) * 100;
    correctedSolids = S - dissolvedSolids;
  }

  // Common downstream formulas (same for WBM and OBM)
  // 6. HGS % vol
  const hgsPercent = (HSG - LSG) !== 0 ? ((avgSG - LSG) / (HSG - LSG)) * S : 0;

  // 7. LGS % vol = retortSolids - HGS % vol
  const lgsPercent = S - hgsPercent;

  // 8. LGS ppb = 3.5 * LSG * LGS % vol
  const lgsLb = 3.5 * LSG * lgsPercent;

  // 9. HGS ppb = 3.5 * HSG * HGS % vol
  const hgsLb = 3.5 * HSG * hgsPercent;

  // 10. Bentonite (%) = bentoniteLb / (2.6 * 3.5)
  const bentPercent = bentLb / (2.6 * 3.5);

  // 11. Drill Solids (%) = LGS % vol - Bentonite % vol
  const drillSolidsPercent = lgsPercent - bentPercent;

  // 12. Drill Solids (lb/bbl) = 3.5 * LSG * Drill Solids %
  const drillSolidsLb = 3.5 * LSG * drillSolidsPercent;

  // 13. DS/Bent Ratio
  const dsBentRatio = bentPercent > 0 ? drillSolidsPercent / bentPercent : 0;

  return {
    mudWeight: MW, retortSolids: S, bariteLb: hgsLb, bentoniteLb: bentLb, brineSG,
    hgsPercent, lgsPercent, lgsLb, hgsLb,
    dissolvedSolids, correctedSolids, bentPercent,
    drillSolidsLb, drillSolidsPercent, dsBentRatio, avgSG,
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