import SolidsAnalysis from "../../modules/SolidAnalysis/solidanalysismodel.js";

// ═══════════════════════════════════════════════════════════════════════════
// PURE CALCULATION — Industry-standard lb/bbl Material Balance Method
// Matches Excel DMR sheet formulas exactly.
//
// References (from industry tutorial documents):
//   TotalSolids(lb/bbl) = MW × 42 × (RetortSolids% / 100)
//   HGS(lb/bbl)         = Barite added (lb/bbl)
//   LGS(lb/bbl)         = TotalSolids - HGS
//   LGS%                = LGS_lb / (MW×42) × 100
//   HGS%                = HGS_lb / (MW×42) × 100
//   Bentonite%          = Bent_lb / (MW×42) × 100
//   DrillSolids(lb/bbl) = LGS - Bentonite
//   DrillSolids%        = DS_lb / (MW×42) × 100
//   DS/Bent Ratio       = DrillSolids_lb / Bentonite_lb
//   DissolvedSolids%    = (BrineSG - 1) × 100
//   CorrectedSolids%    = RetortSolids% - DissolvedSolids%
//   AvgSG               = (HGS_lb×hgsSG + Bent_lb×2.65 + DS_lb×lgsSG) / TotalSolids_lb
//
// BrineSG (OBM): = 0.99707 + 0.007923×CaCl2% + 0.00004964×CaCl2%²
// BrineSG (WBM): = 1.0 (fresh water) or computed from NaCl/CaCl2 if known
// ═══════════════════════════════════════════════════════════════════════════

function computeSolidsAnalysis({
  mudWeight,
  retortSolids,
  oilVol,
  waterVol,
  bariteLb,
  bentoniteLb,
  cacl2Pct,
  oilSG    = 0.81,
  hgsSG    = 4.20,
  lgsSG    = 2.60,
  fluidType = 'Oil-based',
}) {
  const MW      = Number(mudWeight)    || 0;
  const RS      = Number(retortSolids) || 0;   // % vol — retort solids reading
  const barite  = Number(bariteLb)     || 0;   // lb/bbl added
  const bent    = Number(bentoniteLb)  || 0;   // lb/bbl added
  const saltPct = Number(cacl2Pct)     || 0;   // CaCl2 % wt
  const OSG     = Number(oilSG)        || 0.81;
  const HSG     = Number(hgsSG)        || 4.20; // HGS (Barite) SG
  const LSG     = Number(lgsSG)        || 2.60; // LGS (Drill Solids) SG
  const isWBM   = String(fluidType).toLowerCase().includes('water');

  if (MW <= 0) return null;

  const bblFactor = 42; // gallons per barrel

  // ── 1. Total Mud Mass per bbl ─────────────────────────────────────────────
  const totalMudLb = MW * bblFactor;

  // ── 2. Total Solids lb/bbl (from retort) ─────────────────────────────────
  // Formula: MW × 42 × (RetortSolids% / 100)
  const totalSolidsLb = totalMudLb * (RS / 100);

  // ── 3. HGS = Barite added ────────────────────────────────────────────────
  const hgsLb      = barite;
  const hgsPercent = (hgsLb / totalMudLb) * 100;

  // ── 4. LGS = TotalSolids - HGS ───────────────────────────────────────────
  const lgsLb      = Math.max(0, totalSolidsLb - hgsLb);
  const lgsPercent = (lgsLb / totalMudLb) * 100;

  // ── 5. Bentonite ──────────────────────────────────────────────────────────
  const bentPercent = (bent / totalMudLb) * 100;

  // ── 6. Drill Solids = LGS - Bentonite ────────────────────────────────────
  const drillSolidsLb      = Math.max(0, lgsLb - bent);
  const drillSolidsPercent = (drillSolidsLb / totalMudLb) * 100;

  // ── 7. DS / Bentonite Ratio ───────────────────────────────────────────────
  const dsBentRatio = bent > 0 ? drillSolidsLb / bent : 0;

  // ── 8. Brine SG ───────────────────────────────────────────────────────────
  // OBM: polynomial formula from CaCl2% wt
  // WBM: default 1.0 (fresh water / NaCl brine approximation)
  let brineSG;
  if (isWBM) {
    // For WBM with NaCl brine: approximate from saltPct if available
    brineSG = saltPct > 0
      ? 0.99707 + (0.007923 * saltPct) + (0.00004964 * saltPct * saltPct)
      : 1.0;
  } else {
    // OBM: CaCl2-based brine density formula
    brineSG = 0.99707 + (0.007923 * saltPct) + (0.00004964 * saltPct * saltPct);
  }

  // ── 9. Dissolved Solids % ─────────────────────────────────────────────────
  // Formula: (BrineSG - 1) × 100
  const dissolvedSolids = Math.max(0, (brineSG - 1) * 100);

  // ── 10. Corrected Solids % ───────────────────────────────────────────────
  // Formula: RetortSolids% - DissolvedSolids%
  const correctedSolids = Math.max(0, RS - dissolvedSolids);

  // ── 11. Average SG of Solids ─────────────────────────────────────────────
  // Formula: (HGS_lb×hgsSG + Bent_lb×bentSG + DS_lb×lgsSG) / TotalSolids_lb
  // Uses actual SG values from Specific Gravity panel (passed in from Flutter)
  const bentSG = 2.65; // Bentonite SG is always 2.65 (industry standard)
  const avgSG = totalSolidsLb > 0
    ? ((hgsLb * HSG) + (bent * bentSG) + (drillSolidsLb * LSG)) / totalSolidsLb
    : 0;

  return {
    // inputs echoed back
    mudWeight:    +MW.toFixed(3),
    retortSolids: +RS.toFixed(2),
    bariteLb:     +barite.toFixed(2),
    bentoniteLb:  +bent.toFixed(2),
    // calculated
    brineSG:            +brineSG.toFixed(4),
    totalSolidsLb:      +totalSolidsLb.toFixed(2),
    hgsLb:              +hgsLb.toFixed(2),
    hgsPercent:         +hgsPercent.toFixed(2),
    lgsLb:              +lgsLb.toFixed(2),
    lgsPercent:         +lgsPercent.toFixed(2),
    dissolvedSolids:    +dissolvedSolids.toFixed(2),
    correctedSolids:    +correctedSolids.toFixed(2),
    bentPercent:        +bentPercent.toFixed(2),
    drillSolidsLb:      +drillSolidsLb.toFixed(2),
    drillSolidsPercent: +drillSolidsPercent.toFixed(2),
    dsBentRatio:        +dsBentRatio.toFixed(2),
    avgSG:              +avgSG.toFixed(2),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/solids
// ═══════════════════════════════════════════════════════════════════════════
export const createSolidsAnalysis = async (req, res) => {
  try {
    const computed = computeSolidsAnalysis(req.body);
    if (!computed) {
      return res.status(400).json({ success: false, message: "Mud Weight must be > 0" });
    }
    const record = await SolidsAnalysis.create({
      ...computed,
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
    const computed = computeSolidsAnalysis(req.body);
    if (!computed) {
      return res.status(400).json({ success: false, message: "Mud Weight must be > 0" });
    }
    const updated = await SolidsAnalysis.findByIdAndUpdate(
      id,
      {
        $set: {
          ...computed,
          reportId:    req.body.reportId    ?? undefined,
          sampleIndex: req.body.sampleIndex ?? undefined,
        },
      },
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
// GET /api/solids
// ═══════════════════════════════════════════════════════════════════════════
export const getLatestSolidsAnalysis = async (req, res) => {
  try {
    const limit    = parseInt(req.query.limit) || 1;
    const reportId = req.query.reportId || null;
    const query    = reportId ? { reportId } : {};
    const records  = await SolidsAnalysis.find(query)
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();
    if (!records || records.length === 0) {
      return res.status(404).json({ success: false, message: "No records found" });
    }
    return res.status(200).json({
      success: true,
      count:   records.length,
      data:    limit === 1 ? records[0] : records,
    });
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