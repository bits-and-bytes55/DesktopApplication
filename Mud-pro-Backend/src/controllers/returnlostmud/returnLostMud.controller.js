import Pit from "../../modules/pit/pit.model.js";
import Premixed from "../../modules/inventory/premixed.model.js";
import ReturnLostMud from "../../modules/returnlostmud/ReturnLostMud.js";
import { findWritablePitByName, getWritablePits } from "../../utils/pitReportState.js";
import { buildScopedFilter, readReportId } from "../../utils/reportScope.js";

const getWellId = (req) => String(req.params.wellId || "").trim();

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));

const findPremixedMud = async (wellId, premixedMud) => {
  return await Premixed.findOne({
    wellId,
    description: { $regex: `^${String(premixedMud).trim()}$`, $options: "i" },
  });
};

const getAllPits = async (wellId, reportId) => {
  const pits = await getWritablePits({ wellId, reportId });
  if (!pits.length) {
    throw new Error("No pits found for this wellId");
  }
  return pits;
};

const getActivePits = (allPits) => {
  const activePits = allPits.filter((pit) => pit.initialActive === true);
  if (!activePits.length) {
    throw new Error("No active pits found");
  }
  return activePits;
};

const deductFromLocation = async ({ wellId, reportId, from, totalDeduct }) => {
  const allPits = await getAllPits(wellId, reportId);
  const safeFrom = String(from).trim();

  if (safeFrom === "Active System") {
    const activePits = getActivePits(allPits);

    const totalActiveVol = round2(
      activePits.reduce((sum, pit) => sum + toNumber(pit.volume), 0)
    );

    if (totalDeduct > totalActiveVol) {
      throw new Error(
        `Total deduct volume (${totalDeduct}) exceeds Active System volume (${totalActiveVol})`
      );
    }

    let remaining = round2(totalDeduct);

    for (let i = 0; i < activePits.length; i++) {
      const pit = activePits[i];
      if (remaining <= 0) break;

      const pitsLeft = activePits.length - i;
      let deduct = round2(remaining / pitsLeft);

      if (deduct > toNumber(pit.volume)) {
        deduct = round2(toNumber(pit.volume));
      }

      pit.volume = round2(toNumber(pit.volume) - deduct);
      remaining = round2(remaining - deduct);

      await pit.save();
    }

    if (remaining > 0) {
      throw new Error("Unable to deduct full volume from Active System");
    }
  } else {
    const sourcePit = await findWritablePitByName({
      wellId,
      reportId,
      pitName: safeFrom,
    });

    if (!sourcePit) {
      throw new Error(`Source pit '${from}' not found`);
    }

    if (totalDeduct > toNumber(sourcePit.volume)) {
      throw new Error(
        `Total deduct volume (${totalDeduct}) exceeds source pit volume (${toNumber(sourcePit.volume)})`
      );
    }

    sourcePit.volume = round2(toNumber(sourcePit.volume) - totalDeduct);
    await sourcePit.save();
  }
};

const addToLocation = async ({ wellId, reportId, to, returned, mw, mudType }) => {
  if (returned <= 0) return;

  const safeTo = String(to).trim();
  const allPits = await getAllPits(wellId, reportId);

  if (safeTo === "Active System") {
    const activePits = getActivePits(allPits);

    let remaining = round2(returned);

    for (let i = 0; i < activePits.length; i++) {
      const pit = activePits[i];
      const pitsLeft = activePits.length - i;
      const add = round2(remaining / pitsLeft);

      pit.volume = round2(toNumber(pit.volume) + add);
      pit.density = mw;
      pit.fluidType = mudType;

      remaining = round2(remaining - add);
      await pit.save();
    }
  } else if (safeTo !== "Imp") {
    const targetPit = await findWritablePitByName({
      wellId,
      reportId,
      pitName: safeTo,
    });

    if (!targetPit) {
      throw new Error(`Target pit '${to}' not found`);
    }

    targetPit.volume = round2(toNumber(targetPit.volume) + returned);
    targetPit.density = mw;
    targetPit.fluidType = mudType;

    await targetPit.save();
  }
};

const revertDeduction = async ({
  wellId,
  reportId,
  from,
  totalDeduct,
  mw,
  mudType,
}) => {
  if (totalDeduct <= 0) return;

  const allPits = await getAllPits(wellId, reportId);
  const safeFrom = String(from).trim();

  if (safeFrom === "Active System") {
    const activePits = getActivePits(allPits);

    let remaining = round2(totalDeduct);

    for (let i = 0; i < activePits.length; i++) {
      const pit = activePits[i];
      const pitsLeft = activePits.length - i;
      const add = round2(remaining / pitsLeft);

      pit.volume = round2(toNumber(pit.volume) + add);
      pit.density = mw;
      pit.fluidType = mudType;

      remaining = round2(remaining - add);
      await pit.save();
    }
  } else {
    const sourcePit = await findWritablePitByName({
      wellId,
      reportId,
      pitName: safeFrom,
    });

    if (!sourcePit) {
      throw new Error(`Source pit '${from}' not found`);
    }

    sourcePit.volume = round2(toNumber(sourcePit.volume) + totalDeduct);
    sourcePit.density = mw;
    sourcePit.fluidType = mudType;

    await sourcePit.save();
  }
};

const revertAddition = async ({ wellId, reportId, to, returned }) => {
  if (returned <= 0) return;

  const allPits = await getAllPits(wellId, reportId);
  const safeTo = String(to).trim();

  if (safeTo === "Active System") {
    const activePits = getActivePits(allPits);

    let remaining = round2(returned);

    for (let i = 0; i < activePits.length; i++) {
      const pit = activePits[i];
      const pitsLeft = activePits.length - i;
      const deduct = round2(remaining / pitsLeft);

      pit.volume = round2(Math.max(0, toNumber(pit.volume) - deduct));
      remaining = round2(remaining - deduct);
      await pit.save();
    }
  } else if (safeTo !== "Imp") {
    const targetPit = await findWritablePitByName({
      wellId,
      reportId,
      pitName: safeTo,
    });

    if (!targetPit) {
      throw new Error(`Target pit '${to}' not found`);
    }

    targetPit.volume = round2(Math.max(0, toNumber(targetPit.volume) - returned));
    await targetPit.save();
  }
};

const prepareReturnLostMudData = async (wellId, reportId, payload) => {
  const {
    premixedMud,
    from,
    to,
    volReturned,
    mw,
    mudType,
    bol,
    volLost,
    costOfLostPreTax,
    leased,
  } = payload;

  if (!wellId || !premixedMud || !from || !to) {
    throw new Error("wellId, premixedMud, from and to are required");
  }

  const safeWellId = String(wellId).trim();
  const safePremixedMud = String(premixedMud).trim();
  const safeFrom = String(from).trim();
  const safeTo = String(to).trim();

  const returned = round2(toNumber(volReturned));
  const lost = round2(toNumber(volLost));
  const totalDeduct = round2(returned + lost);

  if (returned < 0 || lost < 0) {
    throw new Error("volReturned and volLost cannot be negative");
  }

  if (returned === 0 && lost === 0) {
    throw new Error("Either volReturned or volLost must be greater than 0");
  }

  const premixed = await findPremixedMud(safeWellId, safePremixedMud);

  if (!premixed) {
    throw new Error(`Premixed mud '${premixedMud}' not found for this well`);
  }

  const finalMw =
    mw !== undefined && mw !== null && mw !== ""
      ? round2(toNumber(mw))
      : round2(toNumber(premixed.mw));

  const finalMudType =
    mudType !== undefined && mudType !== null && mudType !== ""
      ? mudType
      : premixed.mudType || "";

  const premixedLeasingFee = round2(toNumber(premixed.leasingFee));

  const finalCostOfLostPreTax =
    costOfLostPreTax !== undefined &&
    costOfLostPreTax !== null &&
    costOfLostPreTax !== ""
      ? round2(toNumber(costOfLostPreTax))
      : round2(lost * premixedLeasingFee);

  return {
    wellId: safeWellId,
    reportId,
    premixedMud: safePremixedMud,
    from: safeFrom,
    to: safeTo,
    volReturned: returned,
    mw: finalMw,
    mudType: finalMudType,
    bol: round2(toNumber(bol)),
    volLost: lost,
    costOfLostPreTax: finalCostOfLostPreTax,
    leased: leased === true || leased === "true",
    totalDeduct,
  };
};

export const createReturnLostMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const payloads = Array.isArray(req.body) ? req.body : [req.body];

    if (!payloads.length) {
      return res.status(400).json({
        success: false,
        message: "Request body is empty",
      });
    }

    const createdItems = [];

    for (const payload of payloads) {
      const prepared = await prepareReturnLostMudData(wellId, reportId, payload);

      await deductFromLocation({
        wellId: prepared.wellId,
        reportId: prepared.reportId,
        from: prepared.from,
        totalDeduct: prepared.totalDeduct,
      });

      await addToLocation({
        wellId: prepared.wellId,
        reportId: prepared.reportId,
        to: prepared.to,
        returned: prepared.volReturned,
        mw: prepared.mw,
        mudType: prepared.mudType,
      });

      const item = await ReturnLostMud.create({
        wellId: prepared.wellId,
        reportId: prepared.reportId,
        premixedMud: prepared.premixedMud,
        from: prepared.from,
        to: prepared.to,
        volReturned: prepared.volReturned,
        mw: prepared.mw,
        mudType: prepared.mudType,
        bol: prepared.bol,
        volLost: prepared.volLost,
        costOfLostPreTax: prepared.costOfLostPreTax,
        leased: prepared.leased,
      });

      createdItems.push(item);
    }

    return res.status(201).json({
      success: true,
      message:
        createdItems.length === 1
          ? "Return / Lost Mud saved successfully"
          : "Multiple Return / Lost Mud records saved successfully",
      count: createdItems.length,
      data: createdItems,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to save Return / Lost Mud",
      error: error.message,
    });
  }
};

export const getReturnLostMudList = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);

    const items = await ReturnLostMud.find(
      buildScopedFilter(wellId, reportId)
    ).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: items.length,
      data: items,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Return / Lost Mud records",
      error: error.message,
    });
  }
};

export const getReturnLostMudById = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const { id } = req.params;

    const item = await ReturnLostMud.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!item) {
      return res.status(404).json({
        success: false,
        message: "Return / Lost Mud record not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Return / Lost Mud record",
      error: error.message,
    });
  }
};

export const updateReturnLostMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const { id } = req.params;

    const existing = await ReturnLostMud.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Return / Lost Mud record not found",
      });
    }

    const oldTotalDeduct = round2(
      toNumber(existing.volReturned) + toNumber(existing.volLost)
    );

    await revertAddition({
      wellId,
      reportId,
      to: existing.to,
      returned: toNumber(existing.volReturned),
    });

    await revertDeduction({
      wellId,
      reportId,
      from: existing.from,
      totalDeduct: oldTotalDeduct,
      mw: toNumber(existing.mw),
      mudType: existing.mudType || "",
    });

    const mergedPayload = {
      premixedMud: req.body.premixedMud ?? existing.premixedMud,
      from: req.body.from ?? existing.from,
      to: req.body.to ?? existing.to,
      volReturned: req.body.volReturned ?? existing.volReturned,
      mw: req.body.mw ?? existing.mw,
      mudType: req.body.mudType ?? existing.mudType,
      bol: req.body.bol ?? existing.bol,
      volLost: req.body.volLost ?? existing.volLost,
      costOfLostPreTax: req.body.costOfLostPreTax ?? existing.costOfLostPreTax,
      leased: req.body.leased ?? existing.leased,
    };

    const prepared = await prepareReturnLostMudData(wellId, reportId, mergedPayload);

    await deductFromLocation({
      wellId: prepared.wellId,
      reportId: prepared.reportId,
      from: prepared.from,
      totalDeduct: prepared.totalDeduct,
    });

    await addToLocation({
      wellId: prepared.wellId,
      reportId: prepared.reportId,
      to: prepared.to,
      returned: prepared.volReturned,
      mw: prepared.mw,
      mudType: prepared.mudType,
    });

    existing.premixedMud = prepared.premixedMud;
    existing.from = prepared.from;
    existing.to = prepared.to;
    existing.volReturned = prepared.volReturned;
    existing.mw = prepared.mw;
    existing.mudType = prepared.mudType;
    existing.bol = prepared.bol;
    existing.volLost = prepared.volLost;
    existing.costOfLostPreTax = prepared.costOfLostPreTax;
    existing.leased = prepared.leased;
    existing.reportId = prepared.reportId;

    await existing.save();

    return res.status(200).json({
      success: true,
      message: "Return / Lost Mud updated successfully",
      data: existing,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update Return / Lost Mud",
      error: error.message,
    });
  }
};

export const deleteReturnLostMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    const { id } = req.params;

    const existing = await ReturnLostMud.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Return / Lost Mud record not found",
      });
    }

    const oldTotalDeduct = round2(
      toNumber(existing.volReturned) + toNumber(existing.volLost)
    );

    await revertAddition({
      wellId,
      reportId,
      to: existing.to,
      returned: toNumber(existing.volReturned),
    });

    await revertDeduction({
      wellId,
      reportId,
      from: existing.from,
      totalDeduct: oldTotalDeduct,
      mw: toNumber(existing.mw),
      mudType: existing.mudType || "",
    });

    await ReturnLostMud.deleteOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    return res.status(200).json({
      success: true,
      message: "Return / Lost Mud deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete Return / Lost Mud",
      error: error.message,
    });
  }
};
