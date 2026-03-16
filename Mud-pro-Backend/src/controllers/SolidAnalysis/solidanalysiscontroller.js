import SolidsAnalysis from "../../modules/SolidAnalysis/solidanalysismodel.js";

// ═══════════════════════════════════════════════════════════════════════════
// PURE CALCULATION — matches Excel DMR formulas exactly
//
// Excel row references (for traceability):
//   L25  = Mud Weight (ppg)
//   L44  = Total Solids (% vol)       = 100 - (Oil + Water)
//   L45  = Corrected Solids (% vol)   = 100 - (Oil + Brine%)
//   L46  = Oil (% vol)
//   L47  = Water (% vol)
//   L54  = CaCl2 (% wt)
//   L57  = LGS Density (SG)           = 2.6 (default)
//   L58  = HGS Density (SG)           = 4.2 (barite default)
//   L59  = Oil Density (SG)           = 0.81 (default)
//   L61  = Brine Density (SG)         = 0.99707 + 0.007923*CaCl2 + 0.00004964*CaCl2²
//   L62  = Brine (% vol)              = Solid Analysis Brine row
//   L63  = Brine Density (from formula)
//   L65  = HGS% (from formula)
//   L67  = Corrected Solids density
//
// Inputs sent from Flutter:
//   mudWeight    (ppg)
//   retortSolids (% vol)  — "*Solids (% vol)" row
//   oilVol       (% vol)  — Oil retort reading
//   waterVol     (% vol)  — Water retort reading
//   bariteLb     (lb/bbl) — Barite added
//   bentoniteLb  (lb/bbl) — Bentonite added
//   cacl2Pct     (% wt)   — CaCl2 (% wt), auto-calc from WM Chlorides
//   oilSG        (SG)     — from Specific Gravity panel, default 0.81
//   hgsSG        (SG)     — HGS density, default 4.2
//   lgsSG        (SG)     — LGS density, default 2.6
//   shaleCec     (meq/100g)
//   bentCec      (meq/100g)
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
  brineSGInput,        // optional override; if not sent, computed from cacl2Pct
}) {
  const MW     = Number(mudWeight)    || 0;
  const RS     = Number(retortSolids) || 0;  // % vol — Total Solids (retort)
  const oil    = Number(oilVol)       || 0;  // % vol
  const water  = Number(waterVol)     || 0;  // % vol
  const barite = Number(bariteLb)     || 0;  // lb/bbl
  const bent   = Number(bentoniteLb)  || 0;  // lb/bbl
  const cacl2  = Number(cacl2Pct)     || 0;  // % wt
  const oilSg  = Number(oilSG)        || 0.81;
  const hgsSg  = Number(hgsSG)        || 4.20;
  const lgsSg  = Number(lgsSG)        || 2.60;

  if (MW <= 0) return null;

  // ── Brine Density (SG) ────────────────────────────────────────────────────
  // Excel: =IFERROR(0.99707+(0.007923*L54)+(0.00004964*(L54^2)),"")
  // L54 = CaCl2 (% wt)
  const brineSG = brineSGInput
    ? Number(brineSGInput)
    : 0.99707 + (0.007923 * cacl2) + (0.00004964 * cacl2 * cacl2);

  // ── Brine % vol = Water % vol (from retort) ───────────────────────────────
  // In oil-based mud, the "Brine" retort reading ≈ Water% (same retort column)
  const brineVol = water;  // % vol

  // ── Corrected Solids % vol ────────────────────────────────────────────────
  // Excel L45: =IFERROR(100-(L46+L62),"")
  // L46=Oil%, L62=Brine% (same as water in OBM retort)
  const correctedSolids = Math.max(0, 100 - (oil + brineVol));

  // ── Total Solids % vol (retort) ───────────────────────────────────────────
  // Excel L44: =IF(100-(L46+L47)<100, 100-(L46+L47), "")
  const totalSolids = Math.max(0, 100 - (oil + water));  // same as RS usually

  // ── Volume balance: 1 bbl = 42 gallons; densities in SG ──────────────────
  // Total fluid volume per bbl in lb: MW × 42
  const mwLbPerBbl = MW * 42;

  // ── HGS (High Gravity Solids = Barite) ───────────────────────────────────
  // Excel L65 HGS% vol: =IFERROR(((L67-L57)/(L58-L57))*L45,"")
  // L67 = Corrected Solids avg density, L57=LGS SG, L58=HGS SG, L45=Corr Solids%
  // We compute avg solids density first via mass balance, then back-calculate HGS%

  // Avg Solids Density (SG) from mass balance:
  // Excel: =IFERROR((100*(L25/8.34)-(L46*L59)-(L61*L62))/L45,"")
  // 8.34 = lb/gal for water (conversion: MW ppg → SG = MW/8.34)
  // numerator = 100*(MW/8.34) - oil%*oilSG - brine%*brineSG
  // denominator = correctedSolids%
  let avgSolidsdens = 0;
  if (correctedSolids > 0) {
    const num = 100 * (MW / 8.34) - (oil * oilSg) - (brineVol * brineSG);
    avgSolidsdens = num / correctedSolids;
  }

  // HGS% vol = ((avgSolidsdens - lgsSg) / (hgsSg - lgsSg)) * correctedSolids
  // Excel: =IFERROR(((L67-L57)/(L58-L57))*L45,"")
  let hgsPercent = 0;
  if (hgsSg !== lgsSg && correctedSolids > 0) {
    hgsPercent = Math.max(0, ((avgSolidsdens - lgsSg) / (hgsSg - lgsSg)) * correctedSolids);
  }

  // HGS lb/bbl = 3.5 × HGS_SG × HGS%
  // Excel: =IFERROR(3.5*L58*L65,"")
  const hgsLb = 3.5 * hgsSg * hgsPercent;

  // ── LGS (Low Gravity Solids) ──────────────────────────────────────────────
  // LGS% vol = Corrected Solids% - HGS%
  // Excel: =IFERROR(L45-L65,"")
  const lgsPercent = Math.max(0, correctedSolids - hgsPercent);

  // LGS lb/bbl = 3.5 × LGS_SG × LGS%
  // Excel: =IFERROR(3.5*L57*L63,"")  — L63 = LGS density, L57 here used as LGS%
  const lgsLb = 3.5 * lgsSg * lgsPercent;

  // ── Dissolved Solids % ────────────────────────────────────────────────────
  // (brineSG - 1) × 100  — fraction of brine that is dissolved solids
  const dissolvedSolids = Math.max(0, (brineSG - 1) * 100);

  // ── Bentonite % vol ───────────────────────────────────────────────────────
  // bentPercent = bentoniteLb / (3.5 × bentSG)  where bentSG ≈ 2.65
  const bentSG = 2.65;
  const bentPercent = bent > 0 ? bent / (3.5 * bentSG) : 0;

  // ── Drill Solids ──────────────────────────────────────────────────────────
  const drillSolidsPercent = Math.max(0, lgsPercent - bentPercent);
  const drillSolidsLb      = 3.5 * lgsSg * drillSolidsPercent;

  // ── DS/Bent Ratio ─────────────────────────────────────────────────────────
  const dsBentRatio = bentPercent > 0 ? drillSolidsPercent / bentPercent : 0;

  // ── Total Solids lb/bbl ───────────────────────────────────────────────────
  const totalSolidsLb = mwLbPerBbl * (RS / 100);

  return {
    // inputs echoed back
    mudWeight:   MW,
    retortSolids: RS,
    oilVol:      oil,
    waterVol:    water,
    bariteLb:    barite,
    bentoniteLb: bent,
    cacl2Pct:    cacl2,
    oilSG:       oilSg,
    hgsSG:       hgsSg,
    lgsSG:       lgsSg,
    // calculated
    brineSG:            +brineSG.toFixed(4),
    brineVol:           +brineVol.toFixed(2),
    correctedSolids:    +correctedSolids.toFixed(2),
    totalSolids:        +totalSolids.toFixed(2),
    totalSolidsLb:      +totalSolidsLb.toFixed(2),
    hgsPercent:         +hgsPercent.toFixed(2),
    hgsLb:              +hgsLb.toFixed(2),
    lgsPercent:         +lgsPercent.toFixed(2),
    lgsLb:              +lgsLb.toFixed(2),
    dissolvedSolids:    +dissolvedSolids.toFixed(2),
    bentPercent:        +bentPercent.toFixed(2),
    drillSolidsPercent: +drillSolidsPercent.toFixed(2),
    drillSolidsLb:      +drillSolidsLb.toFixed(2),
    dsBentRatio:        +dsBentRatio.toFixed(2),
    avgSG:              +avgSolidsdens.toFixed(2),
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
// GET /api/solids
// ═══════════════════════════════════════════════════════════════════════════
export const getLatestSolidsAnalysis = async (req, res) => {
  try {
    const limit    = parseInt(req.query.limit) || 1;
    const reportId = req.query.reportId || null;
    const query    = reportId ? { reportId } : {};
    const records  = await SolidsAnalysis.find(query).sort({ createdAt: -1 }).limit(limit).lean();
    if (!records || records.length === 0) {
      return res.status(404).json({ success: false, message: "No records found" });
    }
    return res.status(200).json({
      success: true,
      count: records.length,
      data: limit === 1 ? records[0] : records,
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