import SolidsAnalysis from "../../modules/SolidAnalysis/solidanalysismodel.js";

// ═══════════════════════════════════════════════════════════════════════════
// HELPER: pure calculation — no DB touch
// ═══════════════════════════════════════════════════════════════════════════
function computeSolidsAnalysis({ mudWeight, retortSolids, oilVol, waterVol, bariteLb, bentoniteLb, cacl2Pct, oilSG, hgsSG, lgsSG }) {
  const MW = Number(mudWeight) || 0;
  // Solids (%) = 100 - (Oil + Water) according to user requirement
  // But backend receives 'retortSolids' as input. We will use that as the base "Solids" (L45 in Excel)
  const S = Number(retortSolids) || 0;
  const O = Number(oilVol) || 0;
  const W = Number(waterVol) || 0;
  const OSG = Number(oilSG) || 0.80;
  const HSG = Number(hgsSG) || 4.20;
  const LSG = Number(lgsSG) || 2.60;
  const saltPct = Number(cacl2Pct) || 0;
  const barite = Number(bariteLb) || 0;
  const bent = Number(bentoniteLb) || 0;

  if (MW <= 0) return null;

  // 1. Brine Density (SG) = 0.99707 + (0.007923 * CaCl2%) + (0.00004964 * (CaCl2%^2))
  const brineSG = 0.99707 + (0.007923 * saltPct) + (0.00004964 * Math.pow(saltPct, 2));

  // 2. Brine (% vol) calculation
  // Usually BrineVol = WaterVol * (100 / (100 - saltPct)) mass-wise adjusted for density?
  // User says Corrected Solids = 100 - (Oil + Brine).
  // In OBM, Salt volume is included in Brine. 
  // Brine Phase Density = (MassWater + MassSalt) / (VolWater + VolSalt)
  // BrineVol = WaterVol * (BrineRelativeVolumeCorrection?)
  // Let's use the assumption that salt increases volume: BrineVol = WaterVol / (1 - (saltPct/100) * (1 - (1/brineSG)))?
  // Simplified for now based on common OBM practice: Salt Vol % = (Brine Mass / Brine SG) - Water Vol
  const brineMass = W * (100 / (100 - saltPct)); // This is an approximation for brine mass contribution per 100 units mud
  const brineVol = saltPct > 0 ? (brineMass / brineSG) : W;

  // 3. Average Solids SG (Avg. SG of Solids)
  // Formula: =IFERROR((100*(L25/8.34)-(L46*L59)-(L61*L62))/L45,"")
  // L25=MW, 8.34 conversion, L46=Oil%, L59=OilSG, L61=BrineSG, L62=BrineVol, L45=Solids%
  const avgSG = S > 0
    ? ( (100 * (MW / 8.34)) - (O * OSG) - (brineVol * brineSG) ) / S
    : 0;

  // 4. HGS % vol = ((avgSG - lgsSG) / (hgsSG - lgsSG)) * Solids%
  const hgsPercent = (HSG - LSG) > 0 ? ((avgSG - LSG) / (HSG - LSG)) * S : 0;

  // 5. LGS % vol = Solids% - HGS % vol
  const lgsPercent = Math.max(0, S - hgsPercent);

  // 6. LGS ppb = 3.5 * LSG * LGS %
  const lgsLb = 3.5 * LSG * lgsPercent;

  // 7. HGS ppb = 3.5 * HSG * HGS %
  const hgsLb = 3.5 * HSG * hgsPercent;

  // 8. Corrected Solids (%) = 100 - (Oil + Brine)
  const correctedSolids = Math.max(0, 100 - (O + brineVol));

  // 9. Dissolved Solids (%) = Salt Volume % (BrineVol - WaterVol)
  const dissolvedSolids = Math.max(0, brineVol - W);

  // 10. Bentonite fields
  const bentPercent = S > 0 ? (bent / (MW * 42)) * 100 : 0; // Keeping existing logic for bent percentage of mud if needed
  // Drill Solids
  const drillSolidsPercent = Math.max(0, lgsPercent - (bentPercent)); // Approximation
  const drillSolidsLb = 3.5 * LSG * drillSolidsPercent;
  const dsBentRatio = bent > 0 ? drillSolidsPercent / bentPercent : 0;

  return {
    mudWeight: MW, retortSolids: S, bariteLb: barite, bentoniteLb: bent, brineSG,
    totalSolidsLb: (MW * 42 * (S / 100)), // Just for record
    hgsLb, hgsPercent, lgsLb, lgsPercent,
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