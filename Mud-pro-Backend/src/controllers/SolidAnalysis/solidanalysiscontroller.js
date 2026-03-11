import SolidsAnalysis from "../../modules/SolidAnalysis/solidanalysismodel.js";

// ═══════════════════════════════════════════════════════════════════════════
// HELPER: pure calculation — no DB touch
// ═══════════════════════════════════════════════════════════════════════════
function computeSolidsAnalysis({ mudWeight, retortSolids, bariteLb, bentoniteLb, brineSG }) {
  const MW = Number(mudWeight) || 0;
  const RS = Number(retortSolids) || 0;
  const barite = Number(bariteLb) || 0;
  const bent = Number(bentoniteLb) || 0;
  const brine = Number(brineSG) || 1.00;

  if (MW <= 0) return null;

  const totalSolidsLb = MW * 42 * (RS / 100);
  const hgsLb = barite;
  const hgsPercent = totalSolidsLb > 0 ? (hgsLb / (MW * 42)) * 100 : 0;
  const lgsLb = Math.max(0, totalSolidsLb - hgsLb);
  const lgsPercent = (lgsLb / (MW * 42)) * 100;
  const dissolvedSolids = (brine - 1) * 100;
  const correctedSolids = Math.max(0, RS - dissolvedSolids);
  const bentPercent = (bent / (MW * 42)) * 100;
  const drillSolidsLb = Math.max(0, lgsLb - bent);
  const drillSolidsPercent = (drillSolidsLb / (MW * 42)) * 100;
  const dsBentRatio = bent > 0 ? drillSolidsLb / bent : 0;
  const avgSG = totalSolidsLb > 0
    ? ((barite * 4.2) + (bent * 2.65) + (drillSolidsLb * 2.6)) / totalSolidsLb
    : 0;

  return {
    mudWeight: MW, retortSolids: RS, bariteLb: barite, bentoniteLb: bent, brineSG: brine,
    totalSolidsLb, hgsLb, hgsPercent, lgsLb, lgsPercent,
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