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

function computeSolidsAnalysis({
  mudWeight, retortSolids, oilVol, waterVol,
  bariteLb, bentoniteLb, cacl2Pct,
  oilSG = 0.81, hgsSG = 4.20, lgsSG = 2.60,
  brineVolPct,   // Brine % vol (L62) — if provided, use directly
  corrSolidsPct, // Corrected Solids % (L45) — if provided, use directly
  fluidType = 'Oil-based',
}) {
  const MW      = Number(mudWeight)     || 0;
  const RS      = Number(retortSolids)  || 0;   // Total Solids % vol (L44)
  const O       = Number(oilVol)        || 0;   // Oil % vol (L46)
  const W       = Number(waterVol)      || 0;   // Water % vol
  const barite  = Number(bariteLb)      || 0;   // lb/bbl
  const bent    = Number(bentoniteLb)   || 0;   // lb/bbl
  const saltPct = Number(cacl2Pct)      || 0;   // CaCl2 % wt (L54)
  const OSG     = Number(oilSG)         || 0.81;
  const HSG     = Number(hgsSG)         || 4.20; // L58
  const LSG     = Number(lgsSG)         || 2.60; // L57

  if (MW <= 0) return null;

  // ── 1. Brine Density SG (L61) ─────────────────────────────────────────────
  // =0.99707+(0.007923*L54)+(0.00004964*(L54^2))
  const brineSG = 0.99707 + (0.007923 * saltPct) + (0.00004964 * saltPct * saltPct);

  // ── 2. Brine % vol (L62) ──────────────────────────────────────────────────
  // If explicitly passed use it, otherwise compute from Water% and BrineSG
  let brineVol;
  if (brineVolPct !== undefined && brineVolPct !== null && Number(brineVolPct) > 0) {
    brineVol = Number(brineVolPct);
  } else if (saltPct > 0 && W > 0) {
    // Brine vol correction: brineVol = (100*W) / (brineSG*(100-saltPct)*0.99707)
    brineVol = (100 * W) / (brineSG * (100 - saltPct) * 0.99707);
  } else {
    brineVol = W; // No salt correction — use Water% directly
  }

  // ── 3. Dissolved Solids % ─────────────────────────────────────────────────
  const dissolvedSolids = Math.max(0, (brineSG - 1) * 100);

  // ── 4. Corrected Solids % (L45) ───────────────────────────────────────────
  // If explicitly passed use it, otherwise compute: 100 - (Oil + Brine)
  let CS;
  if (corrSolidsPct !== undefined && corrSolidsPct !== null && Number(corrSolidsPct) > 0) {
    CS = Number(corrSolidsPct);
  } else {
    CS = 100 - (O + brineVol);
  }
  CS = Math.max(0, CS);

  // ── 5. Total Solids % (L44) ───────────────────────────────────────────────
  const totalSolids = RS > 0 ? RS : Math.max(0, 100 - (O + W));

  // ── 6. Avg Solids Density (L67) ───────────────────────────────────────────
  // =IFERROR((100*(L25/8.34)-(L46*L59)-(L61*L62))/L45,"")
  let avgSG = 0;
  if (CS > 0) {
    avgSG = (100 * (MW / 8.34) - O * OSG - brineSG * brineVol) / CS;
  }

  // ── 7. HGS % vol (L65) ────────────────────────────────────────────────────
  // =IFERROR(((L67-L57)/(L58-L57))*L45,"")
  // L67=AvgSG, L57=LGS_SG, L58=HGS_SG, L45=CorrSolids%
  let hgsPercent = 0;
  if (HSG !== LSG && CS > 0) {
    hgsPercent = ((avgSG - LSG) / (HSG - LSG)) * CS;
  }

  // ── 8. LGS % vol (L63) ────────────────────────────────────────────────────
  // =IFERROR(L45-L65,"")
  const lgsPercent = CS - hgsPercent;

  // ── 9. LGS lb/bbl ─────────────────────────────────────────────────────────
  // =IFERROR(3.5*L57*L63,"")
  const lgsLb = 3.5 * LSG * lgsPercent;

  // ── 10. HGS lb/bbl ────────────────────────────────────────────────────────
  // =IFERROR(3.5*L58*L65,"")
  const hgsLb = 3.5 * HSG * hgsPercent;

  // ── 11. Bentonite % and lb/bbl ────────────────────────────────────────────
  const bentSG = 2.65;
  const bentPercent = bent > 0 ? bent / (3.5 * bentSG) : 0;

  // ── 12. Drill Solids ──────────────────────────────────────────────────────
  const drillSolidsPercent = lgsPercent - bentPercent;
  const drillSolidsLb = 3.5 * LSG * drillSolidsPercent;

  // ── 13. DS/Bent Ratio ─────────────────────────────────────────────────────
  const dsBentRatio = bentPercent > 0 ? drillSolidsPercent / bentPercent : 0;

  // ── 14. Total Solids lb/bbl (for reference) ───────────────────────────────
  const totalSolidsLb = MW * 42 * (totalSolids / 100);

  const fmt = (v) => isNaN(v) || !isFinite(v) ? 0 : +v.toFixed(2);

  return {
    mudWeight:          fmt(MW),
    retortSolids:       fmt(RS),
    bariteLb:           fmt(barite),
    bentoniteLb:        fmt(bent),
    brineSG:            +(brineSG.toFixed(4)),
    brineVol:           fmt(brineVol),
    totalSolids:        fmt(totalSolids),
    totalSolidsLb:      fmt(totalSolidsLb),
    correctedSolids:    fmt(CS),
    dissolvedSolids:    fmt(dissolvedSolids),
    avgSG:              fmt(avgSG),
    hgsPercent:         fmt(hgsPercent),
    hgsLb:              fmt(hgsLb),
    lgsPercent:         fmt(lgsPercent),
    lgsLb:              fmt(lgsLb),
    bentPercent:        fmt(bentPercent),
    drillSolidsPercent: fmt(drillSolidsPercent),
    drillSolidsLb:      fmt(drillSolidsLb),
    dsBentRatio:        fmt(dsBentRatio),
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
    const computed = computeSolidsAnalysis(req.body);
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
    const computed = computeSolidsAnalysis(req.body);
    if (!computed) {
      return res.status(400).json({ success: false, message: "Mud Weight must be > 0" });
    }
    return res.status(200).json({ success: true, message: "Calculated (not saved)", data: computed });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
