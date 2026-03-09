import SolidsAnalysis from "../../modules/SolidAnalysis/solidanalysismodel.js";

export const createSolidsAnalysis = async (req, res) => {
  try {

    const {
      mudWeight,
      retortSolids,
      bariteLb,
      bentoniteLb,
      brineSG
    } = req.body;

    const MW = Number(mudWeight);
    const RS = Number(retortSolids);
    const barite = Number(bariteLb);
    const bent = Number(bentoniteLb);
    const brine = Number(brineSG);

    // =============================
    // TOTAL SOLIDS (lb/bbl)
    // =============================

    const totalSolidsLb = MW * 42 * (RS / 100);

    // =============================
    // HGS (High Gravity Solids)
    // =============================

    const hgsLb = barite;

    const hgsPercent =
      (hgsLb / (MW * 42)) * 100;

    // =============================
    // LGS
    // =============================

    const lgsLb =
      totalSolidsLb - hgsLb;

    const lgsPercent =
      (lgsLb / (MW * 42)) * 100;

    // =============================
    // Dissolved Solids
    // =============================

    const dissolvedSolids =
      (brine - 1) * 100;

    // =============================
    // Corrected Solids
    // =============================

    const correctedSolids =
      RS - dissolvedSolids;

    // =============================
    // Bentonite %
    // =============================

    const bentPercent =
      (bent / (MW * 42)) * 100;

    // =============================
    // Drill Solids
    // =============================

    const drillSolidsLb =
      lgsLb - bent;

    const drillSolidsPercent =
      (drillSolidsLb / (MW * 42)) * 100;

    // =============================
    // DS / Bent Ratio
    // =============================

    const dsBentRatio =
      drillSolidsLb / bent;

    // =============================
    // Average SG
    // =============================

    const avgSG =
      (
        (barite * 4.2) +
        (bent * 2.65) +
        (drillSolidsLb * 2.6)
      ) / totalSolidsLb;

    const result = await SolidsAnalysis.create({

      mudWeight,
      retortSolids,
      bariteLb,
      bentoniteLb,
      brineSG,

      totalSolidsLb,

      hgsLb,
      hgsPercent,

      lgsLb,
      lgsPercent,

      dissolvedSolids,

      correctedSolids,

      bentPercent,

      drillSolidsLb,
      drillSolidsPercent,

      dsBentRatio,

      avgSG

    });

    res.status(201).json({
      success: true,
      message: "Solids Analysis Calculated",
      data: result
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: error.message
    });

  }
};